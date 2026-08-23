import 'package:PawPers/auth/auth_gate.dart';
import 'package:flutter/material.dart';
//import 'screens/onboarding_screen.dart';
import 'app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_home.dart';
//import 'screens/login.dart';
import 'services/emotion_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EmotionService.initialize();

  // DB (Supabase): initialize
  // project's URL + anon key.
  await Supabase.initialize(
    url: 'https://uptrhfbrwanlvhgrcqxm.supabase.co',
    //url: 'https://uptrhfbrwanlvhgrcqxm.supabase.co/rest/v1/',
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
      home: AuthGate(),
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