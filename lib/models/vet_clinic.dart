class VetClinic {
  final String clinicId;
  final String clinicName;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final String? whatsappNumber;
  final String operatingHours;
  final List<String> services;
  final String? imageUrl;

  VetClinic({
    required this.clinicId,
    required this.clinicName,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    this.whatsappNumber,
    required this.operatingHours,
    required this.services,
    this.imageUrl,
  });
}