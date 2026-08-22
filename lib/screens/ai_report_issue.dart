import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';

const _issueOptions = [
  'Wrong emotion detected',
  'Unhelpful resources',
  'App crashed / error',
  'Other',
];

/// "Report Issue" dialog shown from the AI Emotion Analysis result screen.
Future<void> showReportIssueDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const _ReportIssueDialog(),
  );
}

class _ReportIssueDialog extends StatefulWidget {
  const _ReportIssueDialog();

  @override
  State<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<_ReportIssueDialog> {
  // Allows multiple issues to be selected.
  final Set<int> _selectedIssues = {};

  final _detailsController = TextEditingController();

  bool _isSubmitting = false;

  /// Submit the selected issues to Supabase.
  Future<void> _submitReport() async {
    // Make sure the user selected at least one issue.
    if (_selectedIssues.isEmpty) {
      _showErrorDialog(
        'Please select at least one issue.',
      );
      return;
    }

    // Get currently logged-in user.
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showErrorDialog(
        'You must be logged in to submit a report.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {

    final description = _detailsController.text.trim();

    final reports = _selectedIssues.map((index) {
      return {
        'user_id': user.id,
        'issueCategory': _issueOptions[index],
        'description': description,
        'submittedAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'pending',
      };
    }).toList();

      // Insert reports into Supabase.
      await Supabase.instance.client
          .from('ai_report_issue')
          .insert(reports);

      if (!mounted) return;

      // Close the report form.
      Navigator.of(context).pop();

      // Show custom success dialog.
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showErrorDialog(
        'Unable to submit your report. Please try again.',
      );
    }
    //below catch error use to debug to see db connection
    // } catch (e) {
    //   debugPrint('REPORT SUBMISSION ERROR: $e');

    //   if (!mounted) return;

    //   setState(() {
    //     _isSubmitting = false;
    //   });

    //   _showErrorDialog(
    //     'Report submission failed:\n\n$e',
    //   );
    // }
  }

  /// Custom success dialog.
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Report Submitted',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Thank you for helping us improve PawPers. '
                  'Your report has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Custom error dialog.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 32,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Something Went Wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Issue',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'What went wrong?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 4),

            // Multiple issue selection.
            ...List.generate(
              _issueOptions.length,
              (i) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _selectedIssues.contains(i),
                  activeColor: AppColors.accent,
                  title: Text(
                    _issueOptions[i],
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  onChanged: _isSubmitting
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedIssues.add(i);
                            } else {
                              _selectedIssues.remove(i);
                            }
                          });
                        },
                );
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'Describe the issue (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 6),

            TextField(
              controller: _detailsController,
              maxLines: 3,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                hintText: 'Tell us more...',
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                // Cancel button.
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 10),

                // Submit button.
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : _submitReport,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }
}