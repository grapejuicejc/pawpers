import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/image_placeholder.dart';
import 'ai_emotion.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'upload_post.dart';
import 'view_clinics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comments.dart';

/// Root shell shown right after login. Holds the bottom nav and swaps
/// between the 4 real tabs (the 5th "slot" is the "+" button, which opens
/// the upload action sheet instead of navigating).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // Index 2 is the "+" button and never actually renders a page.
  // final _pages = const [
  //   _HomeFeedTab(),
  //   AiEmotionScreen(),
  //   SizedBox.shrink(), // placeholder, never shown (see CustomBottomNav)
  //   ViewClinic(),
  //   ProfileScreen(),
  // ];

  Widget _buildPage() {
    switch (_navIndex) {
      case 0:
        return const _HomeFeedTab();

      case 1:
        return const AiEmotionScreen();

      case 3:
        return const ViewClinic();

      case 4:
        return const ProfileScreen();

      default:
        return const SizedBox.shrink();
    }
  }

  void _onNavTap(int index) {
    if (index == 2) return; // "+" handled by onAddTap, not a real tab
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildPage()),
      bottomNavigationBar: SafeArea(
        child: CustomBottomNav(
          currentIndex: _navIndex,
          onTap: _onNavTap,
          onAddTap: () => showUploadActionSheet(context),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME / COMMUNITY FEED TAB
// ---------------------------------------------------------------------------

const _filterOptions = [
  'All',
  'Discussion',
  'Cats',
  'Adoption',
  'Rescue',
  'Dogs',
];

class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<_HomeFeedTab> {
  String _selectedFilter = 'All';
  bool _isLoading = false;
  List<Post> _posts = [];

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _selectedFilter = filter;
    });

    await _fetchPosts();
  }

  // DB (Supabase):
  // final posts = await SupabaseService.instance.fetchPosts(
  //   keywordFilter: filter,
  // );

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });

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
              ),
               PostReactions (
                reactionID,
                userID
              ),
               PostComments (
                commentID
              )
            ''')
          .order('created_at', ascending: false);

      print('Fetched posts: $data');

      final posts =
          data.map<Post>((row) {
            final profile = row['profiles'];
            final comments = row['PostComments'] ?? [];
            final reactions = row['PostReactions'] ?? [];
            final likeCount = reactions.length;
            final currentUser = supabase.auth.currentUser;

            final isLiked =
                currentUser != null &&
                reactions.any(
                  (reaction) => reaction['userID'] == currentUser.id,
                );

            final List<String> imageUrls = [];

            final images = row['PostImages'];

            if (images != null) {
              for (final image in images) {
                if (image['photoUrl'] != null) {
                  imageUrls.add(image['photoUrl'].toString());
                }
              }
            }

            return Post(
              id: row['postID'].toString(),
              authorId: row['userID'].toString(),
              authorName:
                  profile != null
                      ? profile['username']?.toString() ?? 'Unknown User'
                      : 'Unknown User',
              authorAvatarUrl:
                  profile != null
                      ? profile['profilePhotoUrl']?.toString()
                      : null,
              caption: row['caption']?.toString(),
              imageUrl: imageUrls,
              isLiked: isLiked,
              likeCount: reactions.length,
              commentCount: comments.length,
              createdAt: DateTime.parse(row['created_at'].toString()),
            );
          }).toList();

      print('Converted posts: $posts');

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching posts: $e');
      print(stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load posts: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Community Post',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filterOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final option = _filterOptions[i];
              final selected = option == _selectedFilter;
              return ChoiceChip(
                label: Text(option),
                selected: selected,
                onSelected: (_) => _applyFilter(option),
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.chipGrey,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color:
                      selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                    onRefresh: () => _applyFilter(_selectedFilter),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, i) => _PostCard(post: _posts[i]),
                    ),
                  ),
        ),
      ],
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();

    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
  }

  Future<void> _toggleLike() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      if (_isLiked) {
        // Unlike
        await supabase
            .from('PostReactions')
            .delete()
            .eq('postID', widget.post.id)
            .eq('userID', user.id);

        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        // Like
        await supabase.from('PostReactions').insert({
          'postID': widget.post.id,
          'userID': user.id,
        });

        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // USERNAME
        if (widget.post.authorName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                //profile pic
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.placeholder,
                  backgroundImage:
                      widget.post.authorAvatarUrl != null &&
                              widget.post.authorAvatarUrl!.isNotEmpty
                          ? NetworkImage(widget.post.authorAvatarUrl!)
                          : null,
                  child:
                      widget.post.authorAvatarUrl == null ||
                              widget.post.authorAvatarUrl!.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.textSecondary,
                          )
                          : null,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.post.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        // IMAGES
        if (widget.post.imageUrl.isNotEmpty)
          SizedBox(
            height: 250,
            child: PageView.builder(
              itemCount: widget.post.imageUrl.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.post.imageUrl[index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ImagePlaceholderBox(height: 250);
                    },
                  ),
                );
              },
            ),
          )
        else
          const ImagePlaceholderBox(height: 140),

        const SizedBox(height: 6),

        // // ACCENT BAR
        // Container(
        //   height: 4,
        //   width: 60,
        //   color: AppColors.primary,
        // ),

        // CAPTION
        if (widget.post.caption != null &&
            widget.post.caption!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(widget.post.caption!, style: const TextStyle(fontSize: 13)),
        ],

        //const SizedBox(height: 6),

        // LIKES / COMMENTS
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : AppColors.textSecondary,
                ),
              ),
              Text(
                '$_likeCount Likes',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 16),

             IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Comments(
                      postId: widget.post.id,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.comment_outlined,
                color: AppColors.textSecondary,
              ),
            ),

              Text(
                '${widget.post.commentCount} Comments',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
