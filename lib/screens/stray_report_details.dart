import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import '../models/stray_report.dart';
import 'stray_report_comments.dart';
import 'package:url_launcher/url_launcher.dart';

class StrayReportDetailScreen extends StatelessWidget {
  final StrayReport report;
  final String? highlightCommentId;

  const StrayReportDetailScreen({
    super.key,
    required this.report,
    this.highlightCommentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stray Report',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------
            // USER + STATUS
            // ------------------------------------------------------
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.placeholder,
                  backgroundImage:
                      report.profilePhotoUrl != null &&
                              report.profilePhotoUrl!.isNotEmpty
                          ? NetworkImage(report.profilePhotoUrl!)
                          : null,
                  child:
                      report.profilePhotoUrl == null ||
                              report.profilePhotoUrl!.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.textSecondary,
                          )
                          : null,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    report.username ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.chipGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // IMAGES
            // ------------------------------------------------------
            if (report.imageUrls.isNotEmpty)
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: report.imageUrls.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        report.imageUrls[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const ImagePlaceholderBox(height: 280);
                        },
                      ),
                    );
                  },
                ),
              )
            else
              const ImagePlaceholderBox(height: 200),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // LOCATION
            // ------------------------------------------------------
            if (report.location != null && report.location!.trim().isNotEmpty)
              InkWell(
                onTap: () => _openLocation(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          report.location!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ------------------------------------------------------
            // DESCRIPTION
            // ------------------------------------------------------
            if (report.description != null &&
                report.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(report.description!, style: const TextStyle(fontSize: 14)),
            ],

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 8),

            // ------------------------------------------------------
            // COMMENTS
            // ------------------------------------------------------
            Row(
              children: [
                const Icon(
                  Icons.comment_outlined,
                  color: AppColors.textSecondary,
                ),

                const SizedBox(width: 8),

                Text(
                  '${report.commentCount} Comments',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const Spacer(),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                StrayReportCommentsScreen(strayId: report.id),
                      ),
                    );
                  },
                  child: const Text('View Comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocation(BuildContext context) async {
    final latitude = report.latitude;
    final longitude = report.longitude;

    if (latitude == null || longitude == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }
}
