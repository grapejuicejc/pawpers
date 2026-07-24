import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import 'edit_profile.dart';
import 'my_pets_screen.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _name = 'John Doe';
  String? _bio; // DB (Supabase): load from user profile

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _handleLogout() async {
    // DB (Supabase): await SupabaseService.instance.signOut();
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
            const ImagePlaceholderBox(height: 84, width: 84, borderRadius: 42),
            const SizedBox(height: 10),
            const Text(_name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              _bio ?? 'Add a bio',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                const Text('|', style: TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyPetsScreen()),
                  ),
                  child: const Text('Your Pets', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
                children: const [
                  _PostsTab(),
                  _CommentsTab(),
                  _LikesTab(),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
              title: const Text('Are you a veterinarian?', style: TextStyle(fontSize: 12)),
              subtitle: const Text('Click here to Get Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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

class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(10)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('2 July', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('Post caption / description', style: TextStyle(fontSize: 13)),
                    SizedBox(height: 8),
                    Text('12 Likes   1 Comment', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentsTab extends StatelessWidget {
  const _CommentsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(10)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Replying to: '...'", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('Comment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('25 November', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _LikesTab extends StatelessWidget {
  const _LikesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No liked posts yet.', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
