import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 2));

    // DB (Supabase): once auth is wired up, check Supabase.instance.client.auth
    // .currentSession here. If a session exists, go straight to HomeScreen
    // instead of OnboardingScreen.

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 110,
              width: 110,
              decoration: const BoxDecoration(
                color: AppColors.placeholder,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, size: 44, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'PawPers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}