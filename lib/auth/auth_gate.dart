/*

To continuously listen for auth state changes

unauthenticated - login screen
authenticated - home screen

*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/home_screen.dart';
import '../screens/login.dart';
import '../screens/forgot_password.dart';
import '../screens/forgot_password.dart';
import '../screens/admin/admin_home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      //listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      //builfd appropriate page based on auth state
      builder: (context, snapshot) {
        //loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data?.event;

        // Password recovery session: show reset screen, not HomeScreen
        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordScreen();
        }

        //check if there is a valid session currently
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session == null) {
          return const LoginScreen();
        } else {
          return _RoleRouter(userId: session.user.id);
        }
      },
    );
  }
}

// Looks up the profile's role once per session change, then routes.
class _RoleRouter extends StatefulWidget {
  final String userId;
  const _RoleRouter({required this.userId});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  late final Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture =
        Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', widget.userId)
            .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Profile missing (e.g. deleted) — kick back to login, same as
        // your existing "Account does not exist" handling elsewhere.
        if (snapshot.hasError || snapshot.data == null) {
          Supabase.instance.client.auth.signOut();
          return const LoginScreen();
        }

        final role = snapshot.data!['role'] as String?;

        if (role == 'Admin') {
          return const AdminHomeScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
