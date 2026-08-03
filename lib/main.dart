import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DB (Supabase): initialize 
  // project's URL + anon key.
  await Supabase.initialize(
    url: 'https://uptrhfbrwanlvhgrcqxm.supabase.co/rest/v1/',
    publishableKey: 'sb_publishable_F_HCwCOsz0FqL13X0LCbGw_ptPjVcdj',
  );

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
      //initialRoute: '/',
      routes: {
        //'/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminHomeScreen(),
      },
    );
  }
}
 

//Created 9 July 2026
//Jenna 