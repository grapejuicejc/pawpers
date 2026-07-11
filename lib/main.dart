import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'app_theme.dart';

// DB (Supabase):
// import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DB (Supabase): initialize once you've uncommented supabase_flutter in
  // pubspec.yaml and added your project's URL + anon key.
  // await Supabase.initialize(
  //   url: 'https://YOUR_PROJECT_REF.supabase.co',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  runApp(const PawPersApp());
}

class PawPersApp extends StatelessWidget {
  const PawPersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawPers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingScreen(),
    );
  }
}
 

//Created 9 July 2026
//Jenna 