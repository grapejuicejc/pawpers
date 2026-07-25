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
  final _pages = const [
    _HomeFeedTab(),
    AiEmotionScreen(),
    SizedBox.shrink(), // placeholder, never shown (see CustomBottomNav)
    ViewClinic(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 2) return; // "+" handled by onAddTap, not a real tab
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: _pages,
        ),
      ),
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

const _filterOptions = ['All', 'Discussion', 'Cats', 'Adoption', 'Rescue', 'Dogs'];

class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<_HomeFeedTab> {
  String _selectedFilter = 'All';
  bool _isLoading = false;
  List<Post> _posts = _placeholderPosts;

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
    });

    // DB (Supabase):
    // final posts = await SupabaseService.instance.fetchPosts(
    //   keywordFilter: filter,
    // );

    await Future.delayed(const Duration(milliseconds: 300)); // placeholder delay
    final posts = filter == 'All'
        ? _placeholderPosts
        : _placeholderPosts.where((p) => p.keywords.contains(filter)).toList();

    if (!mounted) return;
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Community Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
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
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
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

class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.authorName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.placeholder,
                  child: Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        const ImagePlaceholderBox(height: 140),
        const SizedBox(height: 6),
        // Thin accent bar under the image — matches the blue strip in the
        // wireframe (can be repurposed as a "seen/unseen" or category marker).
        Container(height: 4, width: 60, color: AppColors.primary),
        if (post.caption != null) ...[
          const SizedBox(height: 8),
          Text(post.caption!, style: const TextStyle(fontSize: 13)),
        ],
        const SizedBox(height: 6),
        Text(
          '${post.likeCount} Likes · ${post.commentCount} Comment${post.commentCount == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// Placeholder data so the feed isn't empty before Supabase is wired up.
// DB (Supabase): delete this once _HomeFeedTabState._applyFilter fetches
// real posts.
final _placeholderPosts = [
  Post(
    id: '1',
    authorId: 'u1',
    authorName: 'Jiah Mashaal',
    caption: 'Max had the best day at the park today! 🐾',
    keywords: const ['Discussion', 'Dogs'],
    likeCount: 12,
    commentCount: 1,
    createdAt: DateTime.now(),
  ),
  Post(
    id: '2',
    authorId: 'u2',
    authorName: 'John Doe',
    caption: 'Looking to adopt — any recommendations near me?',
    keywords: const ['Adoption', 'Cats'],
    likeCount: 5,
    commentCount: 3,
    createdAt: DateTime.now(),
  ),
];

// // ---------------------------------------------------------------------------
// // VIEW NEARBY CLINICS TAB
// // ---------------------------------------------------------------------------

// class _ClinicPlaceholderTab extends StatelessWidget {
//   const _ClinicPlaceholderTab();

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.all(24),
//         child: Text(
//           'View Nearby Clinics tab coming soon.',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: AppColors.textSecondary),
//         ),
//       ),
//     );
//   }
// }