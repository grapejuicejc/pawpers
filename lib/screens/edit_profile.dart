import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _passwordController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _passwordController = TextEditingController();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) return;

      final profile =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();

      _nameController.text = profile['username'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _emailController.text = user.email ?? '';

      if (mounted) {
        setState(() {
          _selectedImageUrl = profile['profilePhotoUrl'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  File? _selectedImage;
  String? _selectedImageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
        ),
      );
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return null;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return null;

    final filePath = '${user.id}/profile.jpg';

    await Supabase.instance.client.storage
        .from('profilepictures')
        .upload(
          filePath,
          _selectedImage!,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = Supabase.instance.client.storage
        .from('profilepictures')
        .getPublicUrl(filePath);

    //return url;
    
     // Cache-bust so Image.network doesn't show a stale cached copy
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _handleSaveChanges() async {
    setState(() => _isSaving = true);

    // DB (Supabase):
    try {
      final service = SupabaseService.instance;
      String? imageUrl = await _uploadProfileImage();

      await service.updateProfile(
        username: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        profilePhotoUrl: imageUrl,
      );

      if (_passwordController.text.isNotEmpty) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));

      Navigator.pop(context, true);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'This action is permanent and cannot be undone. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    // DB (Supabase):
    try {
      await SupabaseService.instance.deleteAccount();
      //await SupabaseService.instance.deleteProfile();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete account: $e"),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child:
                        _selectedImage != null
                            ? Image.file(
                              _selectedImage!,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            )
                            : _selectedImageUrl != null
                            ? Image.network(
                              _selectedImageUrl!,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            )
                            : const ImagePlaceholderBox(
                              height: 90,
                              width: 90,
                              borderRadius: 45,
                            ),
                  ),
                 GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Select from gallery'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('NAME'),
              TextField(controller: _nameController),
              const SizedBox(height: 14),
              _fieldLabel('EMAIL'),
              TextField(
                controller: _emailController,
                readOnly: true,
                enabled: false,
                decoration: const InputDecoration(
                  hintText: 'Email cannot be changed',
                ),
              ),
              const SizedBox(height: 14),
              _fieldLabel('BIO'),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Add a bio'),
              ),
              const SizedBox(height: 14),
              _fieldLabel('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Leave blank to keep current password',
                  hintStyle: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      onPressed: _isSaving ? null : _handleSaveChanges,
                      child:
                          _isSaving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                              : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _handleDeleteAccount,
                icon: const Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.danger,
                  size: 18,
                ),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
