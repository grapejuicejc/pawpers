import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import '../models/stray_report.dart';
import 'stray_report_comments.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StrayReportDetailScreen extends StatefulWidget {
  final StrayReport report;
  final String? highlightCommentId;

  const StrayReportDetailScreen({
    super.key,
    required this.report,
    this.highlightCommentId,
  });

  @override
  State<StrayReportDetailScreen> createState() =>
      _StrayReportDetailScreenState();
}

class _StrayReportDetailScreenState extends State<StrayReportDetailScreen> {
  late String _description;
  late String _status;

  @override
  void initState() {
    super.initState();

    _description = widget.report.description ?? '';
    _status = widget.report.status;
  }

  // ============================================================
  // EDIT DESCRIPTION
  // ============================================================

   Future<void> _editDescription() async {
      final controller = TextEditingController(
        text: _description,
      );

      final newDescription = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit Caption'),
            content: TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter caption...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    controller.text.trim(),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      // IMPORTANT:
      // Do not dispose the controller immediately after showDialog.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });

      if (!mounted || newDescription == null) {
        return;
      }

      try {
        await Supabase.instance.client
            .from('StrayReports')
            .update({
              'description': newDescription,
            })
            .eq('strayID', widget.report.id);

        if (!mounted) return;

        setState(() {
          _description = newDescription;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caption updated successfully.'),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update caption: $e',
            ),
          ),
        );
      }
    }


  // ============================================================
  // CHANGE STATUS
  // ============================================================

  Future<void> _markAsResolved() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text(
          'Are you sure you want to mark this stray report as resolved?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Mark as Resolved'),
          ),
        ],
      );
    },
  );

  if (confirm != true) return;

  try {
    await Supabase.instance.client
        .from('StrayReports')
        .update({
          'status': 'resolved',
        })
        .eq('strayID', widget.report.id);

    if (!mounted) return;

    setState(() {
      _status = 'resolved';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report marked as resolved.'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to mark report as resolved: $e'),
      ),
    );
  }
}

  // ============================================================
  // DELETE REPORT
  // ============================================================

  Future<void> _deleteReport() async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Report'),
          content: const Text(
            'Are you sure you want to delete this stray report? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    try {
      await Supabase.instance.client
          .from('StrayReports')
          .delete()
          .eq('strayID', widget.report.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report deleted successfully.'),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete report: $e'),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stray Report',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editDescription();
              } else if (value == 'resolve') {
                _markAsResolved();
              } else if (value == 'delete') {
                _deleteReport();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit Caption'),
                  ],
                ),
              ),

              if (_status == 'active')
              const PopupMenuItem(
                value: 'resolve',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    SizedBox(width: 10),
                    Text('Mark as Resolved'),
                  ],
                ),
              ),

              const PopupMenuDivider(),

              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Delete Report',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // USER + STATUS
            // ======================================================

            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.placeholder,
                  backgroundImage:
                      widget.report.profilePhotoUrl != null &&
                              widget.report.profilePhotoUrl!.isNotEmpty
                          ? NetworkImage(
                              widget.report.profilePhotoUrl!,
                            )
                          : null,
                  child:
                      widget.report.profilePhotoUrl == null ||
                              widget.report.profilePhotoUrl!.isEmpty
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
                    widget.report.username ?? 'Unknown User',
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
                    _status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ======================================================
            // IMAGES
            // ======================================================

            if (widget.report.imageUrls.isNotEmpty)
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: widget.report.imageUrls.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.report.imageUrls[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const ImagePlaceholderBox(
                            height: 280,
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else
              const ImagePlaceholderBox(
                height: 200,
              ),

            const SizedBox(height: 16),

            // ======================================================
            // LOCATION
            // ======================================================

            if (widget.report.location != null &&
                widget.report.location!.trim().isNotEmpty)
              InkWell(
                onTap: () => _openLocation(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                  ),
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
                          widget.report.location!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration:
                                TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ======================================================
            // DESCRIPTION
            // ======================================================

            if (_description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(
                _description,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 8),

            // ======================================================
            // COMMENTS
            // ======================================================

            Row(
              children: [
                const Icon(
                  Icons.comment_outlined,
                  color: AppColors.textSecondary,
                ),

                const SizedBox(width: 8),

                Text(
                  '${widget.report.commentCount} Comments',
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
                        builder: (_) =>
                            StrayReportCommentsScreen(
                          strayId: widget.report.id,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'View Comments',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OPEN GOOGLE MAPS
  // ============================================================

  Future<void> _openLocation(BuildContext context) async {
    final latitude = widget.report.latitude;
    final longitude = widget.report.longitude;

    if (latitude == null || longitude == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Google Maps.',
          ),
        ),
      );
    }
  }
}