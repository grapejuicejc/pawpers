/// Simple user model used across the app.
/// When Supabase is wired up, this will likely map 1:1 to a `profiles` table row.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.isVerified = false,
  });

  // ---------------------------------------------------------------------
  // DB (Supabase) — uncomment and use once the `profiles` table exists.
  // ---------------------------------------------------------------------
  // factory AppUser.fromMap(Map<String, dynamic> map) {
  //   return AppUser(
  //     id: map['id'] as String,
  //     name: map['name'] as String? ?? '',
  //     email: map['email'] as String? ?? '',
  //     bio: map['bio'] as String?,
  //     avatarUrl: map['avatar_url'] as String?,
  //     isVerified: map['is_verified'] as bool? ?? false,
  //   );
  // }
  //
  // Map<String, dynamic> toMap() {
  //   return {
  //     'id': id,
  //     'name': name,
  //     'email': email,
  //     'bio': bio,
  //     'avatar_url': avatarUrl,
  //     'is_verified': isVerified,
  //   };
  // }
}