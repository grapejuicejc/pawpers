import 'package:PawPers/screens/vet_verification.dart';
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
import '../models/stray_report.dart';

import 'comments.dart';
import 'post_details.dart';
import 'stray_report_details.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final authService = AuthService();

  String? _username;
  String? _bio;
  String? _profilePhotoUrl;
  bool _isVerified = false;

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.instance.getCurrentUserProfile();

    if (!mounted) return;

    setState(() {
      _username = profile?['username'];
      _bio = profile?['bio'];
      _profilePhotoUrl = profile?['profilePhotoUrl'];
       _isVerified = profile?['is_verified'] ?? false; 
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _loadProfile();
  }

  Future<void> _handleLogout() async {
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

            // ---------------------------------------------------------
            // PROFILE PHOTO
            // ---------------------------------------------------------
            _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                ? ClipOval(
                  child: Image.network(
                    _profilePhotoUrl!,
                    height: 84,
                    width: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
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

            // ---------------------------------------------------------
            // USERNAME
            // ---------------------------------------------------------
           Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _username ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified,
                  color: Color.fromARGB(255, 8, 51, 126),
                  size: 18,
                ),
              ],
            ],
          ),

            Text(
              _bio ?? 'Add a bio',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // ---------------------------------------------------------
            // EDIT PROFILE / PETS
            // ---------------------------------------------------------
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyPetsScreen()),
                    );
                  },
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

            // ---------------------------------------------------------
            // TABS
            // ---------------------------------------------------------
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

            // ---------------------------------------------------------
            // VETERINARIAN
            // ---------------------------------------------------------
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VetVerificationScreen(),
                  ),
                );
              },
            ),
          ],
        ),

        // -----------------------------------------------------------
        // LOGOUT
        // -----------------------------------------------------------
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

// ===========================================================================
// POSTS TAB
// ===========================================================================

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

            final images = row['PostImages'] as List? ?? [];
            final reactions = row['PostReactions'] as List? ?? [];
            final comments = row['PostComments'] as List? ?? [];

            final imageUrls =
                images
                    .where((image) => image['photoUrl'] != null)
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

              categories: List<String>.from(row['category'] ?? []),

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
          return _MyPostCard(post: _posts[index]);
        },
      ),
    );
  }
}

// ===========================================================================
// MY POST CARD
// ===========================================================================

class _MyPostCard extends StatelessWidget {
  final Post post;

  const _MyPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
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
            Text(
              formatProfileDate(post.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

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

            if (post.caption != null && post.caption!.trim().isNotEmpty)
              Text(post.caption!, style: const TextStyle(fontSize: 13)),

            const SizedBox(height: 8),

            Text(
              '${post.likeCount} Likes   '
              '${post.commentCount} Comments',
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

// ===========================================================================
// PROFILE COMMENT MODEL
// ===========================================================================

class ProfileComment {
  final String id;

  final String? postId;
  final String? strayId;

  final String body;
  final String previewText;

  final DateTime createdAt;

  final bool isStray;

  const ProfileComment({
    required this.id,
    this.postId,
    this.strayId,
    required this.body,
    required this.previewText,
    required this.createdAt,
    required this.isStray,
  });
}

// ===========================================================================
// PROFILE LIKE MODEL
// ===========================================================================

class ProfileLike {
  final String? postId;
  final String? strayId;

  final String? caption;
  final String? description;
  final String? location;

  final double? latitude;
  final double? longitude;

  final String? username;
  final String? profilePhotoUrl;

  final String? status;

  final List<String> imageUrls;

  final DateTime createdAt;

  final int likeCount;
  final int commentCount;

  final bool isStray;

  const ProfileLike({
    this.postId,
    this.strayId,
    this.caption,
    this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.username,
    this.profilePhotoUrl,
    this.status,
    required this.imageUrls,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.isStray,
  });

  // ---------------------------------------------------------------
  // Convert ProfileLike -> StrayReport
  // ---------------------------------------------------------------

  StrayReport toStrayReport() {
    return StrayReport(
      id: strayId!,
      userId: '',
      description: description,
      latitude: latitude,
      longitude: longitude,
      location: location,
      status: status ?? 'active',
      createdAt: createdAt,
      username: username,
      profilePhotoUrl: profilePhotoUrl,
      imageUrls: imageUrls,
      isLiked: true,
      likeCount: likeCount,
      commentCount: commentCount,
    );
  }
}

// ===========================================================================
// COMMENTS TAB
// ===========================================================================

class _CommentsTab extends StatefulWidget {
  const _CommentsTab();

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  List<ProfileComment> _comments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyComments();
  }

  Future<void> _fetchMyComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      // ============================================================
      // POST COMMENTS
      // ============================================================

      final postData = await supabase
          .from('PostComments')
          .select('''
            commentID,
            postID,
            userID,
            comment,
            created_at,

            Post (
              postID,
              caption
            )
          ''')
          .eq('userID', user.id)
          .order('created_at', ascending: false);

      // ============================================================
      // STRAY REPORT COMMENTS
      // ============================================================

      final strayData = await supabase
          .from('StrayReportComments')
          .select('''
            commentID,
            strayID,
            userID,
            comment,
            created_at,

            StrayReports (
              strayID,
              description,
              location,
              latitude,
              longitude,
              status,
              created_at,

              profiles (
                username,
                profilePhotoUrl
              ),

              StrayReportImages (
                imageID,
                photoUrl
              ),

              StrayReportReactions (
                reactionID,
                userID
              ),

              StrayReportComments (
                commentID
              )
            )
          ''')
          .eq('userID', user.id)
          .order('created_at', ascending: false);

      final List<ProfileComment> comments = [];

      // ============================================================
      // POST COMMENTS
      // ============================================================

      for (final row in postData) {
        final post = row['Post'];

        comments.add(
          ProfileComment(
            id: row['commentID'].toString(),
            postId: row['postID'].toString(),
            body: row['comment']?.toString() ?? '',
            previewText:
                post != null
                    ? post['caption']?.toString() ?? 'Community Post'
                    : 'Community Post',
            createdAt: DateTime.parse(row['created_at'].toString()),
            isStray: false,
          ),
        );
      }

      // ============================================================
      // STRAY COMMENTS
      // ============================================================

      for (final row in strayData) {
        final stray = row['StrayReports'];

        String previewText = 'Stray Report';

        if (stray != null) {
          final description = stray['description']?.toString().trim() ?? '';

          final location = stray['location']?.toString().trim() ?? '';

          if (description.isNotEmpty) {
            previewText = description;
          } else if (location.isNotEmpty) {
            previewText = location;
          }
        }

        comments.add(
          ProfileComment(
            id: row['commentID'].toString(),
            strayId: row['strayID'].toString(),
            body: row['comment']?.toString() ?? '',
            previewText: previewText,
            createdAt: DateTime.parse(row['created_at'].toString()),
            isStray: true,
          ),
        );
      }

      // ============================================================
      // SORT
      // ============================================================

      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('ERROR FETCHING MY COMMENTS: $e');
      print(stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load comments: $e')));
    }
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_comments.isEmpty) {
      return const Center(
        child: Text(
          'You have not commented anything yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyComments,

      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _comments.length,

        separatorBuilder: (_, __) => const SizedBox(height: 12),

        itemBuilder: (context, index) {
          final comment = _comments[index];

          return InkWell(
            borderRadius: BorderRadius.circular(10),

            onTap: () async {
              // ======================================================
              // STRAY REPORT COMMENT
              // ======================================================

              if (comment.isStray && comment.strayId != null) {
                final strayData = await _fetchStrayReport(comment.strayId!);

                if (!context.mounted || strayData == null) {
                  return;
                }

                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => StrayReportDetailScreen(
                          report: strayData,
                          highlightCommentId: comment.id,
                        ),
                  ),
                );

                _fetchMyComments();

                return;
              }

              // ======================================================
              // COMMUNITY POST COMMENT
              // ======================================================

              if (comment.postId != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => PostDetailScreen(
                          postId: comment.postId!,
                          highlightCommentId: comment.id,
                        ),
                  ),
                );

                _fetchMyComments();
              }
            },

            child: Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(10),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Icon(
                              comment.isStray
                                  ? Icons.pets_outlined
                                  : Icons.article_outlined,
                              size: 15,
                              color: AppColors.primary,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              comment.isStray
                                  ? 'Stray Report'
                                  : 'Community Post',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Replying to: '
                          '"${comment.previewText}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          comment.body,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          formatProfileDate(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    comment.isStray
                        ? Icons.pets_outlined
                        : Icons.comment_outlined,
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

// ===========================================================================
// FETCH STRAY REPORT
// ===========================================================================

Future<StrayReport?> _fetchStrayReport(String strayId) async {
  try {
    final supabase = Supabase.instance.client;

    final data =
        await supabase
            .from('StrayReports')
            .select('''
          strayID,
          userID,
          description,
          latitude,
          longitude,
          location,
          status,
          created_at,

          profiles (
            username,
            profilePhotoUrl
          ),

          StrayReportImages (
            imageID,
            photoUrl
          ),

          StrayReportReactions (
            reactionID,
            userID
          ),

          StrayReportComments (
            commentID
          )
        ''')
            .eq('strayID', strayId)
            .maybeSingle();

    if (data == null) {
      return null;
    }

    final profile = data['profiles'];

    final images = data['StrayReportImages'] as List? ?? [];

    final reactions = data['StrayReportReactions'] as List? ?? [];

    final comments = data['StrayReportComments'] as List? ?? [];

    final imageUrls =
        images
            .where((image) => image['photoUrl'] != null)
            .map<String>((image) => image['photoUrl'].toString())
            .toList();

    return StrayReport(
      id: data['strayID'].toString(),

      userId: data['userID'].toString(),

      description: data['description']?.toString(),

      latitude:
          data['latitude'] != null
              ? (data['latitude'] as num).toDouble()
              : null,

      longitude:
          data['longitude'] != null
              ? (data['longitude'] as num).toDouble()
              : null,

      location: data['location']?.toString(),

      status: data['status']?.toString() ?? 'active',

      createdAt: DateTime.parse(data['created_at'].toString()),

      username: profile != null ? profile['username']?.toString() : null,

      profilePhotoUrl:
          profile != null ? profile['profilePhotoUrl']?.toString() : null,

      imageUrls: imageUrls,

      likeCount: reactions.length,

      commentCount: comments.length,

      isLiked: true,
    );
  } catch (e) {
    print('ERROR FETCHING STRAY REPORT: $e');

    return null;
  }
}

// ===========================================================================
// LIKES TAB
// ===========================================================================

class _LikesTab extends StatefulWidget {
  const _LikesTab();

  @override
  State<_LikesTab> createState() => _LikesTabState();
}

class _LikesTabState extends State<_LikesTab> {
  List<ProfileLike> _likes = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyLikes();
  }

  Future<void> _fetchMyLikes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      // ============================================================
      // POST LIKES
      // ============================================================

      final postData = await supabase
          .from('PostReactions')
          .select('''
            reactionID,
            postID,
            userID,

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

      // ============================================================
      // STRAY REPORT LIKES
      // ============================================================

      final strayData = await supabase
          .from('StrayReportReactions')
          .select('''
            reactionID,
            strayID,
            userID,

            StrayReports (
              strayID,
              userID,
              description,
              latitude,
              longitude,
              location,
              status,
              created_at,

              profiles (
                username,
                profilePhotoUrl
              ),

              StrayReportImages (
                imageID,
                photoUrl
              ),

              StrayReportReactions (
                reactionID,
                userID
              ),

              StrayReportComments (
                commentID
              )
            )
          ''')
          .eq('userID', user.id);

      final List<ProfileLike> likes = [];

      // ============================================================
      // POST LIKES
      // ============================================================

      for (final row in postData) {
        final post = row['Post'];

        if (post == null) continue;

        final images = post['PostImages'] as List? ?? [];

        final reactions = post['PostReactions'] as List? ?? [];

        final comments = post['PostComments'] as List? ?? [];

        final imageUrls =
            images
                .where((image) => image['photoUrl'] != null)
                .map<String>((image) => image['photoUrl'].toString())
                .toList();

        likes.add(
          ProfileLike(
            postId: post['postID'].toString(),

            caption: post['caption']?.toString(),

            imageUrls: imageUrls,

            createdAt: DateTime.parse(post['created_at'].toString()),

            likeCount: reactions.length,

            commentCount: comments.length,

            isStray: false,
          ),
        );
      }

      // ============================================================
      // STRAY REPORT LIKES
      // ============================================================

      for (final row in strayData) {
        final stray = row['StrayReports'];

        if (stray == null) continue;

        final images = stray['StrayReportImages'] as List? ?? [];

        final reactions = stray['StrayReportReactions'] as List? ?? [];

        final comments = stray['StrayReportComments'] as List? ?? [];

        final profile = stray['profiles'];

        final imageUrls =
            images
                .where((image) => image['photoUrl'] != null)
                .map<String>((image) => image['photoUrl'].toString())
                .toList();

        likes.add(
          ProfileLike(
            strayId: stray['strayID'].toString(),

            description: stray['description']?.toString(),

            location: stray['location']?.toString(),

            latitude:
                stray['latitude'] != null
                    ? (stray['latitude'] as num).toDouble()
                    : null,

            longitude:
                stray['longitude'] != null
                    ? (stray['longitude'] as num).toDouble()
                    : null,

            status: stray['status']?.toString(),

            username: profile != null ? profile['username']?.toString() : null,

            profilePhotoUrl:
                profile != null ? profile['profilePhotoUrl']?.toString() : null,

            imageUrls: imageUrls,

            createdAt: DateTime.parse(stray['created_at'].toString()),

            likeCount: reactions.length,

            commentCount: comments.length,

            isStray: true,
          ),
        );
      }

      // ============================================================
      // SORT
      // ============================================================

      likes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;

      setState(() {
        _likes = likes;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('ERROR FETCHING MY LIKES: $e');
      print(stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load likes: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_likes.isEmpty) {
      return const Center(
        child: Text(
          'No liked posts or stray reports yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyLikes,

      child: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: _likes.length,

        separatorBuilder: (_, __) => const SizedBox(height: 12),

        itemBuilder: (context, index) {
          return _ProfileLikeCard(like: _likes[index]);
        },
      ),
    );
  }
}

// ===========================================================================
// PROFILE LIKE CARD
// ===========================================================================

class _ProfileLikeCard extends StatelessWidget {
  final ProfileLike like;

  const _ProfileLikeCard({required this.like});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // ==========================================================
        // STRAY REPORT
        // ==========================================================

        if (like.isStray && like.strayId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => StrayReportDetailScreen(report: like.toStrayReport()),
            ),
          );

          return;
        }

        // ==========================================================
        // COMMUNITY POST
        // ==========================================================

        if (like.postId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(postId: like.postId!),
            ),
          );
        }
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
            // -------------------------------------------------------
            // TYPE
            // -------------------------------------------------------
            Row(
              children: [
                Icon(
                  like.isStray ? Icons.pets_outlined : Icons.article_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 6),

                Text(
                  like.isStray ? 'Stray Report' : 'Community Post',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),

                const Spacer(),

                const Icon(Icons.favorite, size: 16, color: Colors.red),
              ],
            ),

            const SizedBox(height: 8),

            // -------------------------------------------------------
            // IMAGES
            // -------------------------------------------------------
            if (like.imageUrls.isNotEmpty)
              SizedBox(
                height: 160,

                child: ListView.separated(
                  scrollDirection: Axis.horizontal,

                  itemCount: like.imageUrls.length,

                  separatorBuilder: (_, __) => const SizedBox(width: 8),

                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),

                      child: Image.network(
                        like.imageUrls[index],
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

            if (like.imageUrls.isNotEmpty) const SizedBox(height: 8),

            // -------------------------------------------------------
            // DESCRIPTION / CAPTION
            // -------------------------------------------------------
            if (like.isStray)
              if (like.description != null &&
                  like.description!.trim().isNotEmpty)
                Text(
                  like.description!,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

            if (!like.isStray)
              if (like.caption != null && like.caption!.trim().isNotEmpty)
                Text(
                  like.caption!,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

            const SizedBox(height: 8),

            // -------------------------------------------------------
            // STATS
            // -------------------------------------------------------
            Text(
              '${like.likeCount} Likes   '
              '${like.commentCount} Comments',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              formatProfileDate(like.createdAt),
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

// ===========================================================================
// DATE HELPERS
// ===========================================================================

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
