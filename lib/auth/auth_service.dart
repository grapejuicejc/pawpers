import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  //sign in with email and password
 Future<void> signInWithEmailPassword(
  String email,
  String password,
) async {
  // Step 1: Check auth.users
  final response = await _client.auth.signInWithPassword(
    email: email,
    password: password,
  );

  final user = response.user;

  if (user == null) {
    throw Exception("Invalid credentials.");
  }


  // Step 2: Check profiles table
  final profile = await _client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();


  // Profile deleted
  if (profile == null) {
    await _client.auth.signOut();

    throw Exception(
      "Account does not exist. Please sign up again.",
    );
  }
}

  //sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;

    if (user == null) {
      throw Exception('Failed to create account.');
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'username': username,
      'email': email,
      'role': 'User',
      'bio': null,
      'profilePhotoUrl': null,
      'is_verified': false,
    });

    return response;
  }

  //sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  //get user email
  String? getCurrentUserEmail() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
