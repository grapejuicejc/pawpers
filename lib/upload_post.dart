import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
                  leading: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                  title: const Text('Add Post', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Share with the community'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.report_gmailerrorred_outlined, color: AppColors.danger),
                  title: const Text(
                    'Report Stray',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
                  ),
                  subtitle: const Text('Help a pet in need'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: navigate to a "Report Stray" flow (location + photo).
                    // Not detailed in the wireframe yet — hook up once designed.
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
  File? _selectedImage;
  bool _isPosting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _handlePost() async {
    if (_captionController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _isPosting = true);

    // DB (Supabase):
    // await SupabaseService.instance.createPost(
    //   caption: _captionController.text.trim(),
    //   imagePath: _selectedImage?.path,
    //   keywords: _selectedKeywords.toList(),
    // );

    await Future.delayed(const Duration(milliseconds: 500)); // placeholder delay

    if (!mounted) return;
    setState(() => _isPosting = false);
    Navigator.of(context).pop();
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
                  const Text(
                    'User Name', // DB (Supabase): replace with current user's name
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: "What's on your mind today?"),
              ),
              const SizedBox(height: 14),
              if (_selectedImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                label: const Text('Add Photos', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Select Keywords', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _keywordOptions.map((keyword) {
                  final selected = _selectedKeywords.contains(keyword);
                  return ChoiceChip(
                    label: Text(keyword),
                    selected: selected,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.chipGrey,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
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
                      onPressed: _isPosting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _handlePost,
                      child: _isPosting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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