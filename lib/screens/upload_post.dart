import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_stray.dart';

/// Bottom sheet shown when the user taps the "+" tab.
/// Matches the "UPLOAD POST SCREEN" wireframe: dimmed background with
/// two options, "Add Post" and "Report Stray".
Future<void> showUploadActionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Add Post',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Share with the community'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreatePostScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.report_gmailerrorred_outlined,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Report Stray',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                  subtitle: const Text('Help a pet in need'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportStrayScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

const _keywordOptions = [
  'Discussion',
  'Advice',
  'Cat',
  'Dog',
  'Missing',
  'Adoption',
  'Lost & Found',
];

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final Set<String> _selectedKeywords = {};
  List<File> _selectedImages = [];
  bool _isPosting = false;
  String? _username;

  Future<void> _pickImages() async {
    final picker = ImagePicker();

    final remainingSlots = 10 - _selectedImages.length;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can upload a maximum of 10 images per post.'),
        ),
      );
      return;
    }

    final pickedImages = await picker.pickMultiImage(imageQuality: 85);

    if (pickedImages.isEmpty) return;

    // Only take images up to the remaining limit
    final imagesToAdd = pickedImages.take(remainingSlots);

    setState(() {
      _selectedImages.addAll(imagesToAdd.map((image) => File(image.path)));
    });

    if (pickedImages.length > remainingSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only 10 images can be uploaded per post.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final profile =
        await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .single();

    if (!mounted) return;

    setState(() {
      _username = profile['username'];
    });
  }

  Future<void> _handlePost() async {
    if (_captionController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    setState(() => _isPosting = true);

    try {
      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User is not logged in.');
      }

      // DB (Supabase):
      final post =
          await Supabase.instance.client
              .from('Post')
              .insert({
                'userID': user.id,
                'caption': _captionController.text.trim(),
              })
              .select()
              .single();

      final postId = post['postID'];

      print('Created post: $postId');

      //upload image to PostImages table
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        // Generate unique file name
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        // Storage path
        final storagePath = '$postId/$fileName';

        // Upload image to Supabase Storage
        await supabase.storage
            .from('post-images')
            .upload(
              storagePath,
              image,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );

        // --------------------------------------------------
        // 3. GET IMAGE URL
        // --------------------------------------------------

        final imageUrl = supabase.storage
            .from('post-images')
            .getPublicUrl(storagePath);

        print('Uploaded image: $imageUrl');

        // --------------------------------------------------
        // 4. SAVE IMAGE URL TO PostImages
        // --------------------------------------------------

        await supabase.from('PostImages').insert({
          'postID': postId,
          'photoUrl': imageUrl,
        });
      }

      print('Post and images uploaded successfully.');

      if (!mounted) return;

      setState(() => _isPosting = false);

      Navigator.of(context).pop();
    } catch (e) {
      print('Error creating post: $e');

      if (!mounted) return;

      setState(() => _isPosting = false);
      Navigator.of(context).pop();

      if (!mounted) return;
      setState(() => _isPosting = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.placeholder,
                    child: Icon(Icons.person, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _username ?? 'Loading...',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "What's on your mind today?",
                ),
              ),
              const SizedBox(height: 14),
              if (_selectedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Add Photos',
                  style: TextStyle(color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Keywords',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _keywordOptions.map((keyword) {
                      final selected = _selectedKeywords.contains(keyword);
                      return ChoiceChip(
                        label: Text(keyword),
                        selected: selected,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.chipGrey,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedKeywords.add(keyword);
                            } else {
                              _selectedKeywords.remove(keyword);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isPosting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _handlePost,
                      child:
                          _isPosting
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Post'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
