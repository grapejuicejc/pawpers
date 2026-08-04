import 'package:PawPers/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/primary_btn.dart';
import '../../services/supabase_service.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _handleSignUp() async {
    final username = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // DB (Supabase):
    // final user = await SupabaseService.instance.signUp(
    //   email,
    //   password,
    //   username,
    // );
     try {
    final user = await SupabaseService.instance.signUp(
      email,
      password,
      username,
    );

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _errorText = 'Registration failed.';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration successful!'),
      ),
    );

    //Navigator.pop(context); // Back to Login screen

  } catch (e) {
    if (!mounted) return;

    setState(() {
      _errorText = e.toString();
    });

  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
//below part works 
  //   try {
  //     await authService.signUpWithEmailPassword(email, password, username);
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //       _errorText = 'Sign up failed.';
  //     });
  //     return;
  //   }

  //    if (!mounted) return;
  // setState(() => _isLoading = false);

  // Always go to Home after registration
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    (route) => false,
  );
    

   
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create New Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 30),
              _fieldLabel('NAME'),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Jane Doe'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('EMAIL'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'sample@mail.com'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('CONFIRM PASSWORD'),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Sign up',
                onPressed: _handleSignUp,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
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
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
