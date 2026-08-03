import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {

  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

   Future<User?> signUp(
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
      return null;
    }

    await _client.from('Users').insert({
      'userID': user.id,
      'username': username,
      'email': email,
      'role': 'user',
    });


    return user;
  }

  Future<User?> signIn(String email, String password) async {

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response.user;
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  final response = await _client
      .from('users')
      .select()
      .eq('user_id', userId)
      .single();

  return response;
}

}

