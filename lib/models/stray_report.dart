class StrayReport {
  final String id;
  final String userId;
  final String? description;
  final double latitude;
  final double longitude;
  final String? location;
  final String status;
  final DateTime createdAt;

  final String? username;
  final String? profilePhotoUrl;

  final List<String> imageUrls;

  StrayReport({
    required this.id,
    required this.userId,
    this.description,
    required this.latitude,
    required this.longitude,
    this.location,
    required this.status,
    required this.createdAt,
    this.username,
    this.profilePhotoUrl,
    required this.imageUrls,
  });

  factory StrayReport.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];

    final images = json['StrayReportImages'] as List? ?? [];

    return StrayReport(
      id: json['strayID'].toString(),
      userId: json['userID'].toString(),
      description: json['description']?.toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      location: json['locationName']?.toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: DateTime.parse(
        json['created_at'].toString(),
      ),

      username: profile?['username']?.toString(),
      profilePhotoUrl:
          profile?['profilePhotoUrl']?.toString(),

      imageUrls: images
          .where((image) => image['photoUrl'] != null)
          .map<String>(
            (image) => image['photoUrl'].toString(),
          )
          .toList(),
    );
  }
}