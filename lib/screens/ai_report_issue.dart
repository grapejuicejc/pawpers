import 'package:flutter/material.dart';
import '../app_theme.dart';

const _issueOptions = [
  'Option #1: Wrong emotion detected',
  'Option #2: No pet detected in photo',
  'Option #3: App crashed / error',
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
  int _selected = 0;
  final _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Issue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Text('What went wrong?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            ...List.generate(_issueOptions.length, (i) {
              return RadioListTile<int>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: i,
                groupValue: _selected,
                activeColor: AppColors.accent,
                title: Text(_issueOptions[i], style: const TextStyle(fontSize: 13)),
                onChanged: (val) => setState(() => _selected = val ?? 0),
              );
            }),
            const SizedBox(height: 8),
            const Text('Describe the issue (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tell us more...'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.textPrimary),
                    onPressed: () {
                      // DB (Supabase):
                      // await SupabaseService.instance.reportEmotionResultIssue(
                      //   option: _issueOptions[_selected],
                      //   details: _detailsController.text.trim(),
                      // );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thanks — your report was submitted.')),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
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