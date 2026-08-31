import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';

class VetVerificationDetailScreen extends StatefulWidget {
  final String verificationId;

  const VetVerificationDetailScreen({super.key, required this.verificationId});

  @override
  State<VetVerificationDetailScreen> createState() =>
      _VetVerificationDetailScreenState();
}

class _VetVerificationDetailScreenState
    extends State<VetVerificationDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await Supabase.instance.client
          .from('vet_verifications')
          .select()
          .eq('id', widget.verificationId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load request: $e';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return AppColors.danger;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Request')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _data == null
                  ? const Center(child: Text('Request not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor(_data!['status'] ?? 'pending')
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (_data!['status'] ?? 'pending')
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(_data!['status'] ?? 'pending'),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _detailRow('Clinic Name', _data!['clinic_name']),
                          _detailRow('Clinic Address', _data!['clinic_address']),
                          _detailRow('Contact No.', _data!['contact_no']),

                          const SizedBox(height: 20),
                          const Text('Submitted Documents',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),

                          if (_data!['document_urls'] != null &&
                              (_data!['document_urls'] as List).isNotEmpty)
                            ...List<String>.from(_data!['document_urls'])
                                .map((path) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.description_outlined,
                                              size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              path.split('/').last,
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                          else
                            const Text('No documents found.'),
                        ],
                      ),
                    ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}