import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // DB (Supabase): pre-fill these from the current AppUser once auth is wired up.
  final _nameController = TextEditingController(text: 'John Doe');
  final _emailController = TextEditingController(text: 'sample@gmail.com');
  final _bioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  Future<void> _handleSaveChanges() async {
    setState(() => _isSaving = true);

    // DB (Supabase):
    // await SupabaseService.instance.updateProfile(
    //   name: _nameController.text.trim(),
    //   bio: _bioController.text.trim(),
    //   // Only send password to Supabase auth.updateUser if it was changed.
    // );

    await Future.delayed(const Duration(milliseconds: 500)); // placeholder delay

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action is permanent and cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // DB (Supabase):
    // await SupabaseService.instance.deleteAccount();
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => const LoginScreen()),
    //   (route) => false,
    // );
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
                  const ImagePlaceholderBox(height: 90, width: 90, borderRadius: 45),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: image_picker -> upload to Supabase Storage `avatars` bucket
                },
                child: const Text('Change Photo'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('NAME'),
              TextField(controller: _nameController),
              const SizedBox(height: 14),
              _fieldLabel('EMAIL'),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _fieldLabel('BIO'),
              TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(hintText: 'Add a bio')),
              const SizedBox(height: 14),
              _fieldLabel('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Leave blank to keep current password'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.textPrimary),
                      onPressed: _isSaving ? null : _handleSaveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _handleDeleteAccount,
                icon: const Icon(Icons.delete_forever_outlined, color: AppColors.danger, size: 18),
                label: const Text('Delete Account', style: TextStyle(color: AppColors.danger)),
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
