import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';

class ViewAiReportIssue extends StatefulWidget {
  const ViewAiReportIssue({super.key});

  @override
  State<ViewAiReportIssue> createState() => _ViewAiReportIssueState();
}

class _ViewAiReportIssueState extends State<ViewAiReportIssue> {
  final _supabase = Supabase.instance.client;

  String _selectedFilter = 'All';

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    try {
    final response = await _supabase
        .from('ai_report_issue')
        .select()
        .order('submittedAt', ascending: false);

      debugPrint('AI REPORTS: $response');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AI REPORT ERROR: $e');
      rethrow;
    }
  }
  

  List<Map<String, dynamic>> _filterReports(
    List<Map<String, dynamic>> reports,
  ) {
    if (_selectedFilter == 'All') {
      return reports;
    }

    return reports.where((report) {
      return report['issueCategory'] == _selectedFilter;
    }).toList();
  }

  Future<void> _markAsReviewed(int reportId) async {
    try {
      await _supabase
          .from('ai_report_issue')
          .update({'status': 'reviewed'})
          .eq('id', reportId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as reviewed.'),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update report.'),
        ),
      );
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    final reportId = report['id'];
    final userId = report['user_id'];
    final category = report['issueCategory'] ?? 'Unknown';
    final description = report['description'] ?? '';
    final status = report['status'] ?? 'pending';
    final submittedAt = report['submittedAt'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Report Details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(
                  'Report ID',
                  reportId.toString(),
                ),

                const SizedBox(height: 12),

                _detailRow(
                  'User ID',
                  userId?.toString() ?? 'Unknown',
                ),

                const SizedBox(height: 12),

                _detailRow(
                  'Issue',
                  category,
                ),

                const SizedBox(height: 12),

                _detailRow(
                  'Status',
                  status,
                ),

                const SizedBox(height: 12),

                _detailRow(
                  'Submitted',
                  _formatDate(submittedAt),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    description.toString().isEmpty
                        ? 'No description provided.'
                        : description.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (status.toString().toLowerCase() != 'reviewed')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markAsReviewed(reportId);
                },
                child: const Text('Mark as Reviewed'),
              ),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Unknown';
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reviewed':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Issue Reports',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        foregroundColor: AppColors.primary,
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Unable to load reports.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allReports = snapshot.data ?? [];
          final reports = _filterReports(allReports);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(allReports),

                const SizedBox(height: 20),

                const Text(
                  'Filter Reports',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                _buildFilter(),

                const SizedBox(height: 20),

                if (reports.isEmpty)
                  _buildEmptyState()
                else
                  ...reports.map(
                    (report) => _buildReportCard(report),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<Map<String, dynamic>> reports) {
    final pendingCount = reports.where((report) {
      return report['status']?.toString().toLowerCase() == 'pending';
    }).length;

    final reviewedCount = reports.where((report) {
      return report['status']?.toString().toLowerCase() == 'reviewed';
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Total',
              reports.length.toString(),
              Icons.analytics_outlined,
            ),
          ),

          Expanded(
            child: _summaryItem(
              'Pending',
              pendingCount.toString(),
              Icons.pending_actions,
            ),
          ),

          Expanded(
            child: _summaryItem(
              'Reviewed',
              reviewedCount.toString(),
              Icons.check_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 25,
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All'),

          const SizedBox(width: 8),

          _filterChip('Wrong emotion detected'),

          const SizedBox(width: 8),

          _filterChip('Unhelpful resources'),

          const SizedBox(width: 8),

          _filterChip('App crashed / error'),

          const SizedBox(width: 8),

          _filterChip('Other'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.accent,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final category =
        report['issueCategory']?.toString() ?? 'Unknown';

    final description =
        report['description']?.toString() ?? '';

    final status =
        report['status']?.toString() ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showReportDetails(report),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                description.isEmpty
                    ? 'No description provided.'
                    : description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),

                  const SizedBox(width: 4),

                  Expanded(
                    child: Text(
                      report['user_id']?.toString() ?? 'Unknown user',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _formatDate(report['submittedAt']),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 55,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            'No reports found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'AI recognition issue reports will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}