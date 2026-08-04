// import 'dart:developer';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class SupabaseService {
//   static final SupabaseService instance = SupabaseService._internal();

//   SupabaseService._internal();

//   final SupabaseClient _client = Supabase.instance.client;

//   Future<User?> signUp(String email, String password, String username) async {
//     try {
//       final response = await _client.auth.signUp(
//         email: email,
//         password: password,
//       );

//       final user = response.user;

//       if (user == null) return null;

//       await _client.from('profiles').insert({
//         'userID': user.id,
//         'username': username,
//         'email': email,
//         'role': 'user',
//       });

//       return user;
//     } catch (e, stackTrace) {
//       log('Sign up failed', error: e, stackTrace: stackTrace);
//       return null;
//     }
//   }

//   Future<User?> signIn(String email, String password) async {
//     try {
//       final response = await _client.auth.signInWithPassword(
//         email: email,
//         password: password,
//       );

//       return response.user;
//     } catch (e, stackTrace) {
//       log('Sign in failed', error: e, stackTrace: stackTrace);
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> getUserProfile(String userId) async {
//     final response =
//         await _client.from('profiles').select().eq('userID', userId).single();

//     return response;
//   }
// }
