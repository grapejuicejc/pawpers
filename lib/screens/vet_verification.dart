import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import 'report_stray.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class VetVerificationScreen extends StatefulWidget {
  const VetVerificationScreen({super.key});

  @override
  State<VetVerificationScreen> createState() => _VetVerificationScreenState();
}

class _VetVerificationScreenState extends State<VetVerificationScreen> {
  final PageController _pageController = PageController();

  final _clinicNameController = TextEditingController();
  //final _clinicAddressController = TextEditingController();
  String? _clinicAddress;
  double? _clinicLatitude;
  double? _clinicLongitude;
  final _contactController = TextEditingController();

  List<PlatformFile> _pickedFiles = [];
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  String? _errorText;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) return;

    final validFiles =
        result.files.where((f) => f.size <= 5 * 1024 * 1024).toList();

    if (validFiles.length != result.files.length && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some files were skipped — max size is 5MB.'),
        ),
      );
    }

    setState(() {
      // Append instead of replace, and skip duplicates (same name + size).
      for (final file in validFiles) {
        final alreadyAdded = _pickedFiles.any(
          (f) => f.name == file.name && f.size == file.size,
        );
        if (!alreadyAdded) _pickedFiles.add(file);
      }
    });
  }

  Future<List<String>> _uploadDocuments(String userId) async {
    final supabase = Supabase.instance.client;
    final paths = <String>[];

    for (final file in _pickedFiles) {
      final path = file.path;
      if (path == null) continue;

      final storagePath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await supabase.storage
          .from('vet-documents')
          .upload(
            storagePath,
            File(path),
            fileOptions: const FileOptions(upsert: false),
          );

      paths.add(storagePath); // store the storage path, bucket is private
    }

    return paths;
  }

  Future<void> _selectClinicLocation() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _clinicLatitude != null && _clinicLongitude != null
              ? LatLng(_clinicLatitude!, _clinicLongitude!)
              : const LatLng(3.1390, 101.6869),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _clinicLatitude = result.location.latitude;
      _clinicLongitude = result.location.longitude;
      _clinicAddress = result.name; 
    });

    // If no name came back (manual map tap/drag), reverse-geocode as fallback.
    if (_clinicAddress == null || _clinicAddress!.trim().isEmpty) {
      try {
        final placemarks = await placemarkFromCoordinates(
          result.location.latitude,
          result.location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[
            if (place.name != null && place.name!.isNotEmpty) place.name!,
            if (place.street != null && place.street!.isNotEmpty) place.street!,
            if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty)
              place.administrativeArea!,
          ];

          setState(() {
            _clinicAddress = parts.join(', ');
          });
        }
      } catch (e) {
        print('Error reverse geocoding clinic location: $e');
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_pickedFiles.isEmpty) {
      setState(() => _errorText = 'Please upload at least one document.');
      return;
    }
    if (_clinicNameController.text.trim().isEmpty) {
      setState(() => _errorText = 'Please enter your clinic name.');
      return;
    }
    if (_clinicAddress == null || _clinicAddress!.trim().isEmpty) {
      setState(() => _errorText = 'Please select your clinic location.');
      return;
    }
    if (_contactController.text.trim().isEmpty) {
      setState(() => _errorText = 'Please enter a contact number.');
      return;
    }
    if (!_acceptedTerms) {
      setState(() => _errorText = 'Please accept the Terms & Conditions.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final documentPaths = await _uploadDocuments(user.id);

      await supabase.from('vet_verifications').insert({
        'user_id': user.id,
        'clinic_name': _clinicNameController.text.trim(),
        'clinic_address': _clinicAddress,
        'clinic_latitude': _clinicLatitude,
        'clinic_longitude': _clinicLongitude,
        'contact_no': _contactController.text.trim(),
        'document_urls': documentPaths,
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request submitted!')),
      );
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veterinarian Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Upload Documents'),
              const Text(
                'Please upload your veterinary license, clinic registration, or other relevant credentials.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickFiles,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.background,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_outlined, size: 28),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Upload Files',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PDF, JPG, or PNG (Max 5MB)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pickedFiles.isNotEmpty) ...[
                const SizedBox(height: 10),
                ..._pickedFiles.map(
                  (f) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined, size: 18),
                    title: Text(f.name, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _pickedFiles.remove(f)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _sectionLabel('Clinic Name'),
              TextField(
                controller: _clinicNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g PetWise Animal Clinic',
                ),
              ),
              const SizedBox(height: 14),
              _sectionLabel('Clinic Address'),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _selectClinicLocation,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    _clinicAddress == null ? 'Select Clinic Location' : 'Change Location',
                  ),
                ),

                if (_clinicAddress != null && _clinicAddress!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _clinicAddress!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 14),
              _sectionLabel('Contact No.'),
              TextField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+6012-345 6789'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'By submitting this request, you confirm the documents provided are authentic and belong to you. False submissions may result in account suspension.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged:
                              (v) =>
                                  setState(() => _acceptedTerms = v ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'I have read and I accept.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          253,
                          231,
                          159,
                        ),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isSubmitting ? null : _submitRequest,
                      child:
                          _isSubmitting
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
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
    ),
  );

  @override
  void dispose() {
    _clinicNameController.dispose();
    //_clinicAddressController.dispose();
    _contactController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
