import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewVetVerification extends StatefulWidget {
  const ReviewVetVerification({super.key});

  @override
  State<ReviewVetVerification> createState() => _ReviewVetVerificationState();
}

class _ReviewVetVerificationState extends State<ReviewVetVerification> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);

    try {
      final data = await Supabase.instance.client
          .from('vet_verifications')
          .select('''
            id, user_id, clinic_name, clinic_address, contact_no,
            document_urls, status, created_at,
            profiles!vet_verifications_user_id_fkey ( username, "profilePhotoUrl", email )
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load requests: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Verification Requests')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _requests.isEmpty
              ? const Center(child: Text('No pending requests.'))
              : RefreshIndicator(
                onRefresh: _fetchRequests,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final profile = req['profiles'];

                    return ListTile(
                      tileColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.divider),
                      ),
                      title: Text(req['clinic_name'] ?? 'Unnamed Clinic'),
                      subtitle: Text(
                        profile != null ? (profile['username'] ?? '') : '',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final acted = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    VetVerificationDetailScreen(request: req),
                          ),
                        );
                        if (acted == true) _fetchRequests();
                      },
                    );
                  },
                ),
              ),
    );
  }
}

class VetVerificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  const VetVerificationDetailScreen({super.key, required this.request});

  @override
  State<VetVerificationDetailScreen> createState() =>
      _VetVerificationDetailScreenState();
}

class _VetVerificationDetailScreenState
    extends State<VetVerificationDetailScreen> {
  bool _isProcessing = false;
  List<String> _signedUrls = [];
  bool _loadingDocs = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentUrls();
  }

  Future<void> _loadDocumentUrls() async {
    final paths = List<String>.from(widget.request['document_urls'] ?? []);
    final urls = <String>[];

    try {
      for (final path in paths) {
        final signed = await Supabase.instance.client.storage
            .from('vet-documents')
            .createSignedUrl(path, 60 * 10); // valid 10 minutes
        urls.add(signed);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load documents: $e')));
    }

    if (!mounted) return;
    setState(() {
      _signedUrls = urls;
      _loadingDocs = false;
    });
  }

  Future<void> _decide(String status) async {
    setState(() => _isProcessing = true);

    try {
      final adminId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client
          .from('vet_verifications')
          .update({
            'status': status,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': adminId,
          })
          .eq('id', widget.request['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'Vet approved!' : 'Request rejected.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final profile = req['profiles'];

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile != null ? (profile['username'] ?? 'User') : 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile != null ? (profile['email'] ?? '') : '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Clinic Name', req['clinic_name']),
              _detailRow('Clinic Address', req['clinic_address']),
              _detailRow('Contact No.', req['contact_no']),
              const SizedBox(height: 16),
              const Text(
                'Documents',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _loadingDocs
                  ? const CircularProgressIndicator()
                  : Column(
                    children:
                        _signedUrls
                            .map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child:
                                    url.toLowerCase().contains('.pdf')
                                        ? ListTile(
                                          leading: const Icon(
                                            Icons.picture_as_pdf_outlined,
                                          ),
                                          title: const Text(
                                            'View document (PDF)',
                                          ),
                                         onTap: () async {
                                            final uri = Uri.parse(url);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            } else if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Could not open document.')),
                                              );
                                            }
                                          },
                                        )
                                         : ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return const SizedBox(
                                                  height: 200,
                                                  child: Center(child: CircularProgressIndicator()),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return SizedBox(
                                                  height: 200,
                                                  child: Center(
                                                    child: Text(
                                                      'Failed to load image:\n$error',
                                                      style: const TextStyle(fontSize: 11, color: Colors.red),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                  ),
                                )
                                .toList(),
                  ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing ? null : () => _decide('rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing ? null : () => _decide('approved'),
                      child:
                          _isProcessing
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Approve'),
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

  Widget _detailRow(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 13),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value?.toString() ?? '-'),
        ],
      ),
    ),
  );
}
