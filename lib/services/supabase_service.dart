import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  Future<User?> signUp(String email, String password, String username) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) return null;

      await _client.from('profiles').insert({
        'id': user.id,
        'username': username,
        'email': email,
        'role': 'User',
        'bio': null,
        'profilePhotoUrl': null,
        'is_verified': false,
      });

      return user;
    } catch (e, stackTrace) {
      log('Sign up failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response.user;
    } catch (e, stackTrace) {
      log('Sign in failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  //   final response =
  //       await _client.from('profiles').select().eq('id', userId).single();

  //   return response;
  // }
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      log("No logged in user");
      return null;
    }

    log("Current user id: ${user.id}");

    final response =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();

    log("Profile data: $response");

    return response;
  }

   Future<void> updateProfile({
    required String username,
    required String bio,
    String? profilePhotoUrl,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      log("No logged in user");
      return;
    };

    await _client
        .from('profiles')
        .update({
          'username': username,
          'bio': bio,
          if(profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
        })
        .eq('id', user.id);
  }

    // Future<void> deleteAccount() async {
    //   final user = _client.auth.currentUser;

    //   if (user == null) {
    //     log("No logged in user");
    //     return;
    //   }

    //   // Delete profile picture
    //   await _client.storage
    //       .from('profilepictures')
    //       .remove([
    //         '${user.id}/profile.jpg'
    //       ]);

    //   // Delete profile row
    //   await _client
    //       .from('profiles')
    //       .delete()
    //       .eq('id', user.id);

    //   // Logout
    //   await _client.auth.signOut();
    // }

 Future<void> deleteAccount() async {
  final response = await _client.functions.invoke('delete-account');

  if (response.status != 200) {
    throw Exception(
      response.data is Map
          ? response.data['error']
          : response.data.toString(),
    );
  }
}

// Future<void> deleteProfile() async {
//   final user = _client.auth.currentUser;

//   if (user == null) {
//     throw Exception("No logged in user.");
//   }

//   // Delete profile picture
//   await _client.storage
//       .from('profilepictures')
//       .remove([
//         '${user.id}/profile.jpg'
//       ]);

//   // Delete profile row
//   await _client
//       .from('profiles')
//       .delete()
//       .eq('id', user.id);
// }

  
}
