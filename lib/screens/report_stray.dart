import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../app_theme.dart';
import 'package:geocoding/geocoding.dart';

class ReportStrayScreen extends StatefulWidget {
  const ReportStrayScreen({super.key});

  @override
  State<ReportStrayScreen> createState() => _ReportStrayScreenState();
}

class _ReportStrayScreenState extends State<ReportStrayScreen> {
  final TextEditingController _descriptionController =
      TextEditingController();

  // final TextEditingController _locationController =
  //     TextEditingController();

  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];

  bool _isSubmitting = false;

  String? _location;
  

  // double? _latitude;
  // double? _longitude;
  LatLng? _selectedLocation;
  //GoogleMapController? _mapController;

  @override
  void dispose() {
    _descriptionController.dispose();
   // _locationController.dispose();
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

    if (_selectedLocation == null) {
      _showError('Please select the location of the stray.');
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
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            'location': _location,
                // _locationController.text.trim().isEmpty
                //     ? null
                //     : _locationController.text.trim(),
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

              // TextField(
              //   controller:
              //       _locationController,
              //   decoration:
              //       const InputDecoration(
              //     hintText:
              //         'e.g. APU, Technology Park Malaysia',
              //     prefixIcon: Icon(
              //       Icons.location_on_outlined,
              //     ),
              //     border: OutlineInputBorder(),
              //   ),
              // ),

              const SizedBox(height: 12),

              // TEMPORARY LOCATION BUTTON
              //
              // We'll replace this with Google Maps /
              // GPS location picker next.
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _selectLocation,
                icon: const Icon(
                  Icons.map_outlined,
                ),
                label: Text(
                  _selectedLocation == null
                      ? 'Select Location'
                      : 'Change Location',
                ),
              ),

            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedLocation != null &&
                        _location != null &&
                        _location!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _location!,
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

                    const SizedBox(height: 3),

                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                      '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // OutlinedButton.icon(
              //   onPressed: () {
              //     setState(() {
              //       _latitude = 3.1390;
              //       _longitude = 101.6869;
              //     });

              //     ScaffoldMessenger.of(
              //       context,
              //     ).showSnackBar(
              //       const SnackBar(
              //         content: Text(
              //           'Temporary location selected.',
              //         ),
              //       ),
              //     );
              //   },
              //   icon: const Icon(
              //     Icons.map_outlined,
              //   ),
              //   label: const Text(
              //     'Select Location',
              //   ),
              // ),

              // if (_latitude != null &&
              //     _longitude != null)
              //   Padding(
              //     padding:
              //         const EdgeInsets.only(
              //       top: 8,
              //     ),
              //     child: Text(
              //       'Coordinates: '
              //       '${_latitude!.toStringAsFixed(5)}, '
              //       '${_longitude!.toStringAsFixed(5)}',
              //       style: const TextStyle(
              //         fontSize: 12,
              //         color:
              //             AppColors.textSecondary,
              //       ),
              //     ),
              //   ),

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

  Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation:
              _selectedLocation ??
              const LatLng(3.1390, 101.6869),
        ),
      ),
    );

    if (result == null) return;

    try {
      final placemarks = await placemarkFromCoordinates(
        result.latitude,
        result.longitude,
      );

      String location = '';

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final parts = <String>[
          if (place.name != null && place.name!.isNotEmpty)
            place.name!,
          if (place.street != null && place.street!.isNotEmpty)
            place.street!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea!,
        ];

        location = parts.join(', ');
      }

      setState(() {
        _selectedLocation = result;
        _location = location;
      });
    } catch (e) {
      print('Error getting location name: $e');

      setState(() {
        _selectedLocation = result;
        _location = null;
      });
    }
  }
  
}

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerScreen({
    super.key,
    required this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState
    extends State<LocationPickerScreen> {
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();

    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation,
              zoom: 16,
            ),

            markers: {
              Marker(
                markerId:
                    const MarkerId('selected-location'),
                position: _selectedLocation,
                draggable: true,

                onDragEnd: (newPosition) {
                  setState(() {
                    _selectedLocation = newPosition;
                  });
                },
              ),
            },

            onTap: (position) {
              setState(() {
                _selectedLocation = position;
              });
            },

            myLocationEnabled: true,
            myLocationButtonEnabled: true,

            // onMapCreated: (controller) {
            //   // optional if we need the controller later
            // },
          ),

          // CONFIRM BUTTON
          Positioned(
            left: 20,
            right: 20,
            bottom: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(_selectedLocation);
              },
              child: const Text(
                'Confirm Location',
              ),
            ),
          ),
        ],
      ),
    );
  }
} //class location picker screen