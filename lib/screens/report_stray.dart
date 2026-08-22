import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';

class ReportStrayScreen extends StatefulWidget {
  const ReportStrayScreen({super.key});

  @override
  State<ReportStrayScreen> createState() => _ReportStrayScreenState();
}

class _ReportStrayScreenState extends State<ReportStrayScreen> {
  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];

  bool _isSubmitting = false;

  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SELECT MULTIPLE IMAGES
  // ------------------------------------------------------------

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isEmpty) return;

      setState(() {
        _selectedImages = images;
      });
    } catch (e) {
      _showError('Failed to select images: $e');
    }
  }

  // ------------------------------------------------------------
  // REMOVE IMAGE
  // ------------------------------------------------------------

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ------------------------------------------------------------
  // SUBMIT REPORT
  // ------------------------------------------------------------

  Future<void> _submitReport() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showError('You must be logged in to report a stray.');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showError('Please select at least one image.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please describe the stray animal.');
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showError('Please provide the location.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // --------------------------------------------------------
      // 1. CREATE STRAY REPORT
      // --------------------------------------------------------

      final report = await supabase
          .from('StrayReports')
          .insert({
            'userID': user.id,
            'description':
                _descriptionController.text.trim(),
            'latitude': _latitude,
            'longitude': _longitude,
            'locationName':
                _locationController.text.trim().isEmpty
                    ? null
                    : _locationController.text.trim(),
            'status': 'active',
          })
          .select('strayID')
          .single();

      final strayId = report['strayID'];

      print('Created stray report: $strayId');

      // --------------------------------------------------------
      // 2. UPLOAD EACH IMAGE
      // --------------------------------------------------------

      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        final file = File(image.path);

        final fileExtension =
            image.path.split('.').last.toLowerCase();

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i.$fileExtension';

        final filePath =
            '${user.id}/$strayId/$fileName';

        await supabase.storage
            .from('stray-reports')
            .upload(
              filePath,
              file,
              fileOptions: const FileOptions(
                upsert: false,
              ),
            );

        // ------------------------------------------------------
        // 3. GET PUBLIC URL
        // ------------------------------------------------------

        final imageUrl = supabase.storage
            .from('stray-reports')
            .getPublicUrl(filePath);

        print('Uploaded image: $imageUrl');

        // ------------------------------------------------------
        // 4. SAVE URL TO DATABASE
        // ------------------------------------------------------

        await supabase.from('StrayReportImages').insert({
          'strayID': strayId,
          'photoUrl': imageUrl,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Stray report submitted successfully!',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      print('Error submitting stray report: $e');
      print(stackTrace);

      if (!mounted) return;

      _showError(
        'Failed to submit stray report: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // ERROR MESSAGE
  // ------------------------------------------------------------

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Stray',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ------------------------------------------------
              // PHOTOS
              // ------------------------------------------------

              const Text(
                'Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Add photos of the stray animal.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection:
                        Axis.horizontal,
                    itemCount:
                        _selectedImages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                    itemBuilder:
                        (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(12),
                            child: Image.file(
                              File(
                                _selectedImages[index]
                                    .path,
                              ),
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),

                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () =>
                                  _removeImage(index),
                              child: Container(
                                decoration:
                                    const BoxDecoration(
                                  color: Colors.black54,
                                  shape:
                                      BoxShape.circle,
                                ),
                                padding:
                                    const EdgeInsets.all(
                                      4,
                                    ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : _pickImages,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                label: const Text(
                  'Add Photos',
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // DESCRIPTION
              // ------------------------------------------------

              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _descriptionController,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Describe the stray animal...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // LOCATION
              // ------------------------------------------------

              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _locationController,
                decoration:
                    const InputDecoration(
                  hintText:
                      'e.g. APU, Technology Park Malaysia',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // TEMPORARY LOCATION BUTTON
              //
              // We'll replace this with Google Maps /
              // GPS location picker next.

              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _latitude = 3.1390;
                    _longitude = 101.6869;
                  });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Temporary location selected.',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.map_outlined,
                ),
                label: const Text(
                  'Select Location',
                ),
              ),

              if (_latitude != null &&
                  _longitude != null)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 8,
                  ),
                  child: Text(
                    'Coordinates: '
                    '${_latitude!.toStringAsFixed(5)}, '
                    '${_longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // ------------------------------------------------
              // SUBMIT
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting
                          ? null
                          : _submitReport,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}