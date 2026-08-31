import 'package:flutter/material.dart';
import '../models/vet_clinic.dart';
import '../services/clinic_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicDetailsPage extends StatelessWidget {
  final VetClinic clinic;
  final Map<String, dynamic> details;

  const ClinicDetailsPage({
    super.key,
    required this.clinic,
    required this.details,
  });

  Future<void> _openDirections() async {
    final latitude = clinic.latitude;
    final longitude = clinic.longitude;
    final address = clinic.address;

    final query =
      address.trim().isNotEmpty
          ? address.trim()
          : '$latitude,$longitude';

    // Google Maps URL
    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}",
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callClinic() async {
    final phone = details["formatted_phone_number"];

    if (phone == null || phone.toString().isEmpty) {
      return;
    }

    final phoneUrl = Uri(scheme: 'tel', path: phone.toString());

    try {
      final launched = await launchUrl(phoneUrl);

      if (!launched) {
        debugPrint("Could not launch phone: $phoneUrl");
      }
    } catch (e) {
      debugPrint("Error launching phone: $e");
    }
  }
  //============================================================

  Future<void> _openWebsite() async {
    final website = details["website"];

    if (website == null || website.toString().trim().isEmpty) {
      return;
    }

    String websiteString = website.toString().trim();

    if (!websiteString.startsWith('http://') &&
        !websiteString.startsWith('https://')) {
      websiteString = 'https://$websiteString';
    }

    final websiteUrl = Uri.parse(websiteString);

    try {
      final launched = await launchUrl(
        websiteUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint("Could not launch website: $websiteUrl");
      }
    } catch (e) {
      debugPrint("Error launching website: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = ClinicService().getPhotoUrl(details);

    return Scaffold(
      appBar: AppBar(title: Text(clinic.clinicName)),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLINIC IMAGE
            photoUrl != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    photoUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                : Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: const Center(
                    child: Icon(Icons.local_hospital, size: 80),
                  ),
                ),

            const SizedBox(height: 20),

            // CLINIC NAME
            Text(
              clinic.clinicName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // RATING
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 22),

                const SizedBox(width: 5),
                Text(
                  "${details["rating"] ?? "N/A"}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(width: 8),
                Text(
                  "(${details["user_ratings_total"] ?? 0} reviews)",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // INFORMATION
            _infoCard(
              Icons.location_on,
              "Address",
              clinic.address,
              _openDirections,
            ),

            _infoCard(
              Icons.phone,
              "Phone",
              details["formatted_phone_number"] ?? "Phone unavailable",
              details["formatted_phone_number"] != null ? _callClinic : null,
            ),

            _infoCard(
              Icons.language,
              "Website",
              details["website"] ?? "Website unavailable",
              details["website"] != null ? _openWebsite : null,
            ),

            const SizedBox(height: 20),

            // OPENING HOURS
            const Text(
              "Opening Hours",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (details["opening_hours"] != null)
              ...List<String>.from(
                details["opening_hours"]["weekday_text"],
              ).map(
                (hour) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(hour),
                ),
              )
            else
              const Text("Opening hours unavailable"),

            const SizedBox(height: 25),

            // REVIEWS
            const Text(
              "Reviews",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (details["reviews"] != null)
              ...List.generate(
                details["reviews"].length > 3 ? 3 : details["reviews"].length,
                (index) {
                  final review = details["reviews"][index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            review["author_name"] ?? "Anonymous",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 5),
                          Text(review["text"] ?? ""),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              const Text("No reviews available"),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String value,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      color: const Color(0xFFFFF3B0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Row(
            children: [
              Icon(icon),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 4),

                    Text(value),
                  ],
                ),
              ),

              if (onTap != null) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
