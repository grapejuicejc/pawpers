class StrayReport {
  final String id;
  final String userId;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String status;
  final DateTime createdAt;
  final String? username;
  final String? profilePhotoUrl;
  final List<String> imageUrls;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final bool isVerified;

  const StrayReport({
    required this.id,
    required this.userId,
    this.description,
    this.latitude,
    this.longitude,
    this.location,
    required this.status,
    required this.createdAt,
    this.username,
    this.profilePhotoUrl,
    required this.imageUrls,
    this.isLiked = false,
    this.likeCount = 0,
    this.commentCount = 0,
    required this.isVerified,
  });

  factory StrayReport.fromJson(
    Map<String, dynamic> json, {
    bool isLiked = false,
    int likeCount = 0,
    int commentCount = 0,
  }) {
    final profile = json['profiles'];

    final images = json['StrayReportImages'] as List? ?? [];

    return StrayReport(
      id: json['strayID'].toString(),
      userId: json['userID'].toString(),
      description: json['description']?.toString(),
      latitude:
          json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,

      longitude:
          json['longitude'] != null
              ? (json['longitude'] as num).toDouble()
              : null,

      location: json['location']?.toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: DateTime.parse(json['created_at'].toString()),

      username: profile?['username']?.toString(),
      profilePhotoUrl: profile?['profilePhotoUrl']?.toString(),
      isVerified:
          profile != null ? (profile['isVerified'] as bool? ?? false) : false,

      imageUrls:
          images
              .where((image) => image['photoUrl'] != null)
              .map<String>((image) => image['photoUrl'].toString())
              .toList(),

      isLiked: isLiked,
      likeCount: likeCount,
      commentCount: commentCount,
    );
  }
}
