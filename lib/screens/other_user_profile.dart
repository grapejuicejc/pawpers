import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> pets = [];

  bool isLoading = true;
  String? errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get profile
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (profileData == null) {
        throw Exception('User profile not found.');
      }

      // Get user's posts
      final postData = await supabase
          .from('Post')
          .select()
          .eq('userID', widget.userId)
          .order('created_at', ascending: false);

      // Get user's pets
      final petData = await supabase
          .from('Pets')
          .select()
          .eq('userID', widget.userId)
          .order('petName', ascending: true);

      if (!mounted) return;

      setState(() {
        profile = Map<String, dynamic>.from(profileData);

        posts = List<Map<String, dynamic>>.from(
          (postData as List).map(
            (post) => Map<String, dynamic>.from(post),
          ),
        );

        pets = List<Map<String, dynamic>>.from(
          (petData as List).map(
            (pet) => Map<String, dynamic>.from(pet),
          ),
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String _getString(String key) {
    final value = profile?[key];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  bool _getBool(String key) {
    final value = profile?[key];

    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  void _showProfilePicture() {
    final imageUrl = _getString('profilePhotoUrl');

    if (imageUrl.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 250,
                        height: 250,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture() {
    final imageUrl = _getString('profilePhotoUrl');

    return GestureDetector(
      onTap: _showProfilePicture,
      child: CircleAvatar(
        radius: 55,
        backgroundColor: Colors.grey.shade300,
        backgroundImage:
            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? const Icon(
                Icons.person,
                size: 55,
                color: Colors.grey,
              )
            : null,
      ),
    );
  }

  Widget _buildProfileHeader() {
    final username = _getString('username');
    final bio = _getString('bio');
    final isVerified = _getBool('is_verified');

    return Column(
      children: [
        const SizedBox(height: 15),

        _buildProfilePicture(),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              username.isNotEmpty ? username : 'User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (isVerified) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.verified,
                color: Colors.blue,
                size: 20,
              ),
            ],
          ],
        ),

        if (bio.isNotEmpty) ...[
          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: Text(
            'No posts yet.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(posts[index]);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final caption = post['caption']?.toString() ?? '';
    final createdAt = post['created_at']?.toString() ?? '';

    String displayDate = '';

    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);

        displayDate =
            '${date.day} ${_monthName(date.month)}';
      } catch (_) {
        displayDate = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayDate.isNotEmpty)
            Text(
              displayDate,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

          const SizedBox(height: 10),

          if (caption.isNotEmpty)
            Text(
              caption,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 14),

          Row(
            children: [
              Text(
                '${post['likesCount'] ?? 0} Likes',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 12),

              Text(
                '${post['commentsCount'] ?? 0} Comments',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetsTab() {
    if (pets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: Text(
            'No pets added yet.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        return _buildPetCard(pets[index]);
      },
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final name = pet['petName']?.toString() ?? 'Pet';
    final breed = pet['petBreed']?.toString() ?? '';
    final age = pet['petAge']?.toString() ?? '';
    final photoUrl = pet['petPhotoUrl']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? const Icon(
                    Icons.pets,
                    color: Colors.grey,
                  )
                : null,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (breed.isNotEmpty)
                  Text(
                    breed,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                if (age.isNotEmpty)
                  Text(
                    '$age years old',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // No bottom navigation bar here
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.grey,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildProfileHeader(),

                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.black,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Pets'),
                      ],
                    ),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostsTab(),
                          _buildPetsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}