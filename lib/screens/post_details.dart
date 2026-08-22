import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/post.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import 'comments.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String? highlightCommentId;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.highlightCommentId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;

  bool _isLoading = true;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  // ---------------------------------------------------------------------------
  // FETCH POST
  // ---------------------------------------------------------------------------

  Future<void> _fetchPost() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('Post')
          .select('''
            postID,
            userID,
            caption,
            created_at,

            profiles (
              username,
              profilePhotoUrl
            ),

            PostImages (
              imageID,
              photoUrl
            )
          ''')
          .eq('postID', widget.postId)
          .maybeSingle();

      if (data == null) {
        throw Exception('Post not found.');
      }

      print('POST DETAIL: $data');

      final profile = data['profiles'];

      final List<dynamic> imageData =
          data['PostImages'] ?? [];

      final List<String> imageUrls = [];

      for (final image in imageData) {
        final url = image['photoUrl']?.toString();

        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }

      final post = Post(
        id: data['postID'].toString(),

        authorId: data['userID'].toString(),

        authorName:
            profile != null
                ? profile['username']?.toString() ?? 'Unknown User'
                : 'Unknown User',

        authorAvatarUrl:
            profile != null
                ? profile['profilePhotoUrl']?.toString()
                : null,

        caption:
            data['caption']?.toString(),

        imageUrl: imageUrls,

        keywords: const [],

        likeCount: 0,

        commentCount: 0,

        createdAt: DateTime.parse(
          data['created_at'].toString(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _post = post;
        _likeCount = post.likeCount;
        _isLoading = false;
      });

      // Get the actual number of likes.
      await _loadLikeInformation();

      // If we came from Profile > Comments,
      // automatically open the comments sheet.
      if (widget.highlightCommentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _openComments();
          }
        });
      }
    } catch (e) {
      print('Error fetching post: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load post: $e',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD LIKE INFORMATION
  // ---------------------------------------------------------------------------

  Future<void> _loadLikeInformation() async {
    try {
      final supabase = Supabase.instance.client;

      final reactions = await supabase
          .from('PostReactions')
          .select('userID')
          .eq('postID', widget.postId);

      final user = supabase.auth.currentUser;

      final liked = user != null &&
          reactions.any(
            (reaction) =>
                reaction['userID'].toString() == user.id,
          );

      if (!mounted) return;

      setState(() {
        _likeCount = reactions.length;
        _isLiked = liked;
      });
    } catch (e) {
      print('Error loading likes: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LIKE / UNLIKE
  // ---------------------------------------------------------------------------

  Future<void> _toggleLike() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to like posts.'),
        ),
      );

      return;
    }

    try {
      if (_isLiked) {
        await supabase
            .from('PostReactions')
            .delete()
            .eq('postID', widget.postId)
            .eq('userID', user.id);

        if (!mounted) return;

        setState(() {
          _isLiked = false;

          if (_likeCount > 0) {
            _likeCount--;
          }
        });
      } else {
        await supabase
            .from('PostReactions')
            .insert({
          'postID': widget.postId,
          'userID': user.id,
        });

        if (!mounted) return;

        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update like: $e',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN COMMENTS
  // ---------------------------------------------------------------------------

  void _openComments() {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.80,

          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),

            child: Comments(
              postId: widget.postId,

              highlightCommentId:
                  widget.highlightCommentId,
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _post == null
              ? const Center(
                  child: Text('Post not found.'),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPost,

                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      30,
                    ),

                    child: _buildPost(),
                  ),
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // POST UI
  // ---------------------------------------------------------------------------

  Widget _buildPost() {
    final post = _post!;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        // ---------------------------------------------------------------------
        // USER
        // ---------------------------------------------------------------------

        Row(
          children: [

            CircleAvatar(
              radius: 20,

              backgroundColor:
                  AppColors.placeholder,

              backgroundImage:
                  post.authorAvatarUrl != null &&
                          post.authorAvatarUrl!
                              .isNotEmpty
                      ? NetworkImage(
                          post.authorAvatarUrl!,
                        )
                      : null,

              child:
                  post.authorAvatarUrl == null ||
                          post.authorAvatarUrl!
                              .isEmpty
                      ? const Icon(
                          Icons.person,
                          color:
                              AppColors.textSecondary,
                        )
                      : null,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    post.authorName,

                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    formatPostTime(
                      post.createdAt,
                    ),

                    style: const TextStyle(
                      fontSize: 11,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // IMAGES
        // ---------------------------------------------------------------------

        if (post.imageUrl.isNotEmpty)

          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),

            child: SizedBox(
              height: 360,

              child: PageView.builder(
                itemCount:
                    post.imageUrl.length,

                itemBuilder:
                    (context, index) {

                  return Image.network(
                    post.imageUrl[index],

                    width:
                        double.infinity,

                    fit: BoxFit.cover,

                    loadingBuilder:
                        (
                          context,
                          child,
                          loadingProgress,
                        ) {
                      if (loadingProgress ==
                          null) {
                        return child;
                      }

                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    },

                    errorBuilder:
                        (
                          context,
                          error,
                          stackTrace,
                        ) {
                      return const ImagePlaceholderBox(
                        height: 360,
                      );
                    },
                  );
                },
              ),
            ),
          )

        else

          const ImagePlaceholderBox(
            height: 250,
          ),

        const SizedBox(height: 12),

        // ---------------------------------------------------------------------
        // LIKE + COMMENT
        // ---------------------------------------------------------------------

        Row(
          children: [

            IconButton(
              onPressed: _toggleLike,

              icon: Icon(
                _isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,

                color:
                    _isLiked
                        ? Colors.red
                        : AppColors.textSecondary,
              ),
            ),

            Text(
              '$_likeCount Likes',

              style: const TextStyle(
                fontSize: 12,
                color:
                    AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: 12),

            IconButton(
              onPressed: _openComments,

              icon: const Icon(
                Icons.comment_outlined,
                color:
                    AppColors.textSecondary,
              ),
            ),

            const Text(
              'Comments',

              style: TextStyle(
                fontSize: 12,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],
        ),

        // ---------------------------------------------------------------------
        // CAPTION
        // ---------------------------------------------------------------------

        if (post.caption != null &&
            post.caption!.trim().isNotEmpty) ...[

          const SizedBox(height: 4),

          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),

              children: [

                TextSpan(
                  text: '${post.authorName} ',

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                TextSpan(
                  text: post.caption!,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// POST TIME FORMATTER
// =============================================================================

String formatPostTime(DateTime createdAt) {
  final malaysiaTime =
      createdAt.toUtc().add(
        const Duration(hours: 8),
      );

  final now =
      DateTime.now().toUtc().add(
        const Duration(hours: 8),
      );

  final difference =
      now.difference(malaysiaTime);

  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  if (malaysiaTime.year == now.year) {
    return '${malaysiaTime.day} '
        '${_monthName(malaysiaTime.month)}';
  }

  return '${malaysiaTime.day} '
      '${_monthName(malaysiaTime.month)} '
      '${malaysiaTime.year}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}