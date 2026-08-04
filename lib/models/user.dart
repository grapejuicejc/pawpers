class AppUser {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? bio;
  final String? profilePhotoUrl;
  final bool isVerified;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.bio,
    this.profilePhotoUrl,
    this.isVerified = false,
  });


  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'User',
      bio: map['bio'] as String?,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      isVerified: map['is_verified'] as bool? ?? false,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'bio': bio,
      'profilePhotoUrl': profilePhotoUrl,
      'is_verified': isVerified,
    };
  }
}