import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/primary_btn.dart';
import 'registration.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // DB (Supabase):
    // final user = await SupabaseService.instance.signIn(email, password);
    // if (user == null) {
    //   setState(() { _isLoading = false; _errorText = 'Invalid credentials.'; });
    //   return;
    // }

    await Future.delayed(const Duration(milliseconds: 600)); // placeholder delay

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const ImagePlaceholderBox(height: 90, width: 90, borderRadius: 45),
              const SizedBox(height: 20),
              const Text(
                'Hello :)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'The PawPers community missed you!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _fieldLabel('EMAIL'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'sample@gmail.com'),
              ),
              const SizedBox(height: 14),
              _fieldLabel('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(_errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: forgot-password flow (Supabase: client.auth.resetPasswordForEmail)
                  },
                  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Login', onPressed: _handleLogin, isLoading: _isLoading),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                ),
                child: const Text.rich(
                  TextSpan(
                    text: 'New User? ',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Sign up here.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}