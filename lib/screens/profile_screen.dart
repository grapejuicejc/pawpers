import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import 'edit_profile.dart';
import 'my_pets_screen.dart';
import 'login.dart';
import '../../auth/auth_service.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import 'comments.dart';
import 'post_details.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final authService = AuthService();

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.instance.getCurrentUserProfile();

    if (!mounted) return;

    setState(() {
      _username = profile?['username'];
      _bio = profile?['bio'];
      _profilePhotoUrl = profile?['profilePhotoUrl'];
    });

    print("IMAGE URL: $_profilePhotoUrl");
  }

  String? _username;
  String? _bio;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  Future<void> _handleLogout() async {
    // DB (Supabase):
    await authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            //const ImagePlaceholderBox(height: 84, width: 84, borderRadius: 42),
            _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                ? ClipOval(
                  child: Image.network(
                    _profilePhotoUrl!,
                    height: 84,
                    width: 84,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        print("IMAGE LOADED");
                        return child;
                      }

                      print("LOADING IMAGE...");
                      return const CircularProgressIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("IMAGE ERROR: $error");
                      return const ImagePlaceholderBox(
                        height: 84,
                        width: 84,
                        borderRadius: 42,
                      );
                    },
                  ),
                )
                : const ImagePlaceholderBox(
                  height: 84,
                  width: 84,
                  borderRadius: 42,
                ),
            const SizedBox(height: 10),
            Text(
              _username ?? 'User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              _bio ?? 'Add a bio',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );

                    if (updated == true) {
                      await _loadProfile();
                    }
                  },
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  '|',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyPetsScreen()),
                      ),
                  child: const Text(
                    'Your Pets',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Post'),
                Tab(text: 'Comments'),
                Tab(text: 'Likes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_PostsTab(), _CommentsTab(), _LikesTab()],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.verified_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              title: const Text(
                'Are you a veterinarian?',
                style: TextStyle(fontSize: 12),
              ),
              subtitle: const Text(
                'Click here to Get Verified',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onTap: () {},
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: AppColors.danger),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// TABS
// ---------------------------------------------------------------------------

class _PostsTab extends StatefulWidget {
  const _PostsTab();

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

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
            ),

            PostReactions (
              reactionID,
              userID
            ),

            PostComments (
              commentID
            )
          ''')
          .eq('userID', user.id)
          .order('created_at', ascending: false);

      final posts =
          data.map<Post>((row) {
            final profile = row['profiles'];

            final images = row['PostImages'] ?? [];
            final reactions = row['PostReactions'] ?? [];
            final comments = row['PostComments'] ?? [];

            final imageUrls =
                (images as List)
                    .map<String>((image) => image['photoUrl'].toString())
                    .toList();

            return Post(
              id: row['postID'].toString(),
              authorId: row['userID'].toString(),

              authorName:
                  profile != null
                      ? profile['username']?.toString() ?? 'User'
                      : 'User',

              authorAvatarUrl:
                  profile != null
                      ? profile['profilePhotoUrl']?.toString()
                      : null,

              caption: row['caption']?.toString(),

              imageUrl: imageUrls,

              likeCount: reactions.length,

              commentCount: comments.length,

              createdAt: DateTime.parse(row['created_at'].toString()),
            );
          }).toList();

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching my posts: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load your posts: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          'You have not posted anything yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyPosts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _posts[index];

          return _MyPostCard(post: post);
        },
      ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  final Post post;

  const _MyPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: post.id,
            ),
          ),
        );
      },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE
          Text(
            formatProfileDate(post.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          // IMAGES
          if (post.imageUrl.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: post.imageUrl.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.imageUrl[index],
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const ImagePlaceholderBox(
                          height: 160,
                          width: 160,
                        );
                      },
                    ),
                  );
                },
              ),
            ),

          if (post.imageUrl.isNotEmpty) const SizedBox(height: 8),

          // CAPTION
          if (post.caption != null && post.caption!.trim().isNotEmpty)
            Text(post.caption!, style: const TextStyle(fontSize: 13)),

          const SizedBox(height: 8),

          // STATS
          Text(
            '${post.likeCount} Likes   ${post.commentCount} Comments',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

String formatProfileDate(DateTime createdAt) {
  final malaysiaTime = createdAt.toUtc().add(const Duration(hours: 8));

  final now = DateTime.now().toUtc().add(const Duration(hours: 8));

  final difference = now.difference(malaysiaTime);

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
    return '${malaysiaTime.day} ${_monthName(malaysiaTime.month)}';
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


class _CommentsTab extends StatefulWidget {
  const _CommentsTab();

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  List<PostComment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyComments();
  }

  Future<void> _fetchMyComments() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('PostComments')
          .select('''
            commentID,
            postID,
            userID,
            comment,
            created_at,

            profiles (
              username,
              profilePhotoUrl
            ),

            Post (
              caption
            )
          ''')
          .eq('userID', user.id)
          .order('created_at', ascending: false);

      print('MY COMMENTS: $data');

      final comments = data.map<PostComment>((row) {
        final profile = row['profiles'];
        final post = row['Post'];

        return PostComment(
          id: row['commentID'].toString(),

          postId: row['postID'].toString(),

          authorId: row['userID'].toString(),

          authorName:
              profile != null
                  ? profile['username']?.toString() ?? 'Unknown User'
                  : 'Unknown User',

          authorAvatarUrl:
              profile != null
                  ? profile['profilePhotoUrl']?.toString()
                  : null,

          body: row['comment']?.toString() ?? '',

          repliedToCaptionPreview:
              post != null
                  ? post['caption']?.toString() ?? ''
                  : '',

          createdAt: DateTime.parse(
            row['created_at'].toString(),
          ),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('ERROR FETCHING MY COMMENTS: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load comments: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_comments.isEmpty) {
      return const Center(
        child: Text(
          'You have not commented anything yet.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyComments,

      child: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: _comments.length,

        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),

        itemBuilder: (context, index) {
          final comment = _comments[index];

          return InkWell(
            borderRadius: BorderRadius.circular(10),

            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    postId: comment.postId,
                    highlightCommentId: comment.id,
                  ),
                ),
              );

              // Refresh when coming back.
              _fetchMyComments();
            },

            child: Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.divider,
                ),

                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // ---------------------------------------------------------
                  // COMMENT
                  // ---------------------------------------------------------

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        // POST CAPTION
                        Text(
                          comment.repliedToCaptionPreview
                                  .isNotEmpty
                              ? 'Replying to: "${comment.repliedToCaptionPreview}"'
                              : 'Replying to a post',

                          maxLines: 2,

                          overflow:
                              TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 11,
                            color:
                                AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // USER'S COMMENT
                        Text(
                          comment.body,

                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // DATE
                        Text(
                          formatCommentTime(
                            comment.createdAt,
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

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LikesTab extends StatefulWidget {
  const _LikesTab();

  @override
  State<_LikesTab> createState() => _LikesTabState();
}

class _LikesTabState extends State<_LikesTab> {
  List<Post> _likedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedPosts();
  }

  Future<void> _fetchLikedPosts() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final data = await supabase
          .from('PostReactions')
          .select('''
            postID,

            Post (
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
              ),

              PostReactions (
                reactionID,
                userID
              ),

              PostComments (
                commentID
              )
            )
          ''')
          .eq('userID', user.id);

      final posts =
          data.map<Post>((row) {
            final post = row['Post'];

            if (post == null) {
              throw Exception('Post not found');
            }

            final profile = post['profiles'];

            final images = post['PostImages'] ?? [];
            final reactions = post['PostReactions'] ?? [];
            final comments = post['PostComments'] ?? [];

            final imageUrls =
                (images as List)
                    .map<String>((image) => image['photoUrl'].toString())
                    .toList();

            return Post(
              id: post['postID'].toString(),
              authorId: post['userID'].toString(),

              authorName:
                  profile != null
                      ? profile['username']?.toString() ?? 'User'
                      : 'User',

              authorAvatarUrl:
                  profile != null
                      ? profile['profilePhotoUrl']?.toString()
                      : null,

              caption: post['caption']?.toString(),

              imageUrl: imageUrls,

              likeCount: reactions.length,

              commentCount: comments.length,

              isLiked: true,

              createdAt: DateTime.parse(post['created_at'].toString()),
            );
          }).toList();

      if (!mounted) return;

      setState(() {
        _likedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching liked posts: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load liked posts: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_likedPosts.isEmpty) {
      return const Center(
        child: Text(
          'No liked posts yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLikedPosts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _likedPosts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _MyPostCard(post: _likedPosts[index]);
        },
      ),
    );
  }
}
