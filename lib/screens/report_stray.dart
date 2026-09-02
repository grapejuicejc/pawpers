import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../app_theme.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      if (source == ImageSource.gallery) {
        // Allow multiple images from gallery
        final images = await _picker.pickMultiImage(
          imageQuality: 80,
        );

        if (images.isEmpty) return;

        setState(() {
          _selectedImages.addAll(images);
        });
      } else {
        // Take one photo with camera
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (image == null) return;

        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showError('Failed to select image: $e');
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
            'status': 'active',
          })
          .select('strayID')
          .single();

      final strayId = report['strayID'];

      print('Created stray report: $strayId');


      // 2. UPLOAD EACH IMAGE
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        final file = File(image.path);

        final fileExtension =
            image.path.split('.').last.toLowerCase();

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i.$fileExtension';

        final filePath = '${user.id}/$strayId/$fileName';

        await supabase.storage
            .from('stray-reports')
            .upload(
              filePath,
              file,
              fileOptions: const FileOptions(
                upsert: false,
              ),
            );

        // 3. GET PUBLIC URL
        final imageUrl = supabase.storage
            .from('stray-reports')
            .getPublicUrl(filePath);

        print('Uploaded image: $imageUrl');

        // 4. SAVE URL TO DATABASE
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

                  ],
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

    Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation:
              _selectedLocation ??
              const LatLng(3.1390, 101.6869),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _selectedLocation = result.location;
      _location = result.name;
    });
  }

  // Future<void> _selectLocation() async {
  //   final result = await Navigator.of(context).push<LocationPickerResult>(
  //     MaterialPageRoute(
  //       builder: (_) => LocationPickerScreen(
  //         initialLocation:
  //             _selectedLocation ??
  //             const LatLng(3.1390, 101.6869),
  //       ),
  //     ),
  //   );

  //   if (result == null) return;

  //   try {
  //     final placemarks = await placemarkFromCoordinates(
  //       result.location.latitude,
  //       result.location.longitude,
        
  //     );

  //     String location = '';
    

  //     if (placemarks.isNotEmpty) {
  //       final place = placemarks.first;

  //       final parts = <String>[
  //         if (place.name != null && place.name!.isNotEmpty)
  //           place.name!,
  //         if (place.street != null && place.street!.isNotEmpty)
  //           place.street!,
  //         if (place.locality != null && place.locality!.isNotEmpty)
  //           place.locality!,
  //         if (place.administrativeArea != null &&
  //             place.administrativeArea!.isNotEmpty)
  //           place.administrativeArea!,
  //       ];

  //       location = parts.join(', ');
  //     }

  //     setState(() {
  //       _selectedLocation = result.location;
  //       _location = location;
  //     });
  //   } catch (e) {
  //     print('Error getting location name: $e');

  //     setState(() {
  //       _selectedLocation = result.location;
  //       _location = null;
  //     });
  //   }
  // }
  
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

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  
  static const String _googleApiKey = 'AIzaSyD3pyhrWt673U3iiK4WmRiyWdN3THCZdPc';

  final TextEditingController _searchController =
      TextEditingController();

  GoogleMapController? _mapController;

  Timer? _debounce;

  late LatLng _selectedLocation;
  String? _selectedPlaceName;  

  bool _isLoadingLocation = true;
  bool _isSearching = false;

  // ============================================================
  // SEARCH RESULTS
  // ============================================================

  List<_PlacePrediction> _predictions = [];

  // Session token groups autocomplete requests and the subsequent
  // place selection into one search session.
  String _sessionToken =
      DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();

    _selectedLocation = widget.initialLocation;

    _initializeLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE LOCATION
  // ============================================================

  Future<void> _initializeLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      // ----------------------------------------------------------
      // LOCATION SERVICE OFF
      // ----------------------------------------------------------

      if (!serviceEnabled) {
        if (!mounted) return;

        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Location is turned off',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: const Text(
                'Please turn on your device location '
                'so PawPers can show your current location.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Turn On'),
                ),
              ],
            );
          },
        );

        if (shouldOpenSettings == true) {
          await Geolocator.openLocationSettings();

          // Give the settings screen a moment to close/update.
          await Future.delayed(
            const Duration(milliseconds: 500),
          );

          final enabledAfterSettings =
              await Geolocator.isLocationServiceEnabled();

          if (enabledAfterSettings) {
            await _getCurrentLocation();
          } else {
            _finishLoading();
          }
        } else {
          _finishLoading();
        }

        return;
      }

      // ----------------------------------------------------------
      // CHECK PERMISSION
      // ----------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // ----------------------------------------------------------
      // PERMISSION DENIED
      // ----------------------------------------------------------

      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showLocationMessage(
            'Location permission is required to use your current location.',
          );
        }

        _finishLoading();
        return;
      }

      // ----------------------------------------------------------
      // PERMISSION DENIED FOREVER
      // ----------------------------------------------------------

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Location Permission Required',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: const Text(
                'Location permission has been permanently denied. '
                'Please enable it from your device settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Settings'),
                ),
              ],
            );
          },
        );

        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }

        _finishLoading();
        return;
      }

      // ----------------------------------------------------------
      // GET CURRENT LOCATION
      // ----------------------------------------------------------

      await _getCurrentLocation();
    } catch (e) {
      print('Error initializing location: $e');

      _finishLoading();
    }
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation = currentLocation;
        _isLoadingLocation = false;
      });

      // Move map to user's current location.
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation,
              zoom: 16,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');

      _finishLoading();
    }
  }

  void _finishLoading() {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = false;
    });
  }

  // ============================================================
  // SEARCH TEXT CHANGED
  // ============================================================

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });

      return;
    }

    // Wait briefly so we don't send an API request for every
    // single keystroke.
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () {
        _searchPlaces(value.trim());
      },
    );
  }

  // ============================================================
  // GOOGLE PLACES AUTOCOMPLETE
  // ============================================================

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final uri = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );

      final body = {
        'input': input,

        // Bias results around the user's current map location.
        'locationBias': {
          'circle': {
            'center': {
              'latitude': _selectedLocation.latitude,
              'longitude': _selectedLocation.longitude,
            },
            'radius': 50000.0,
          },
        },

        // Malaysia.
        'includedRegionCodes': ['my'],

        // English results.
        'languageCode': 'en',

        'sessionToken': _sessionToken,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,

          // Only request the information we actually need.
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.text,'
              'suggestions.placePrediction.structuredFormat',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print(
          'Places API error: '
          '${response.statusCode} ${response.body}',
        );

        if (mounted) {
          setState(() {
            _predictions = [];
            _isSearching = false;
          });
        }

        return;
      }

      final decoded = jsonDecode(response.body);

      final suggestions =
          decoded['suggestions'] as List? ?? [];

      final results = <_PlacePrediction>[];

      for (final suggestion in suggestions) {
        final placePrediction =
            suggestion['placePrediction'];

        if (placePrediction == null) {
          continue;
        }

        final placeId =
            placePrediction['placeId']?.toString();

        final textObject =
            placePrediction['text'];

        final structuredFormat =
            placePrediction['structuredFormat'];

        if (placeId == null || textObject == null) {
          continue;
        }

        final mainText =
            structuredFormat?['mainText']?['text']
                ?.toString();

        final secondaryText =
            structuredFormat?['secondaryText']?['text']
                ?.toString();

        final fullText =
            textObject['text']?.toString() ?? '';

        results.add(
          _PlacePrediction(
            placeId: placeId,
            description: fullText,
            mainText: mainText ?? fullText,
            secondaryText: secondaryText ?? '',
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _predictions = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching Places API: $e');

      if (!mounted) return;

      setState(() {
        _predictions = [];
        _isSearching = false;
      });
    }
  }

  // ============================================================
  // SELECT SEARCH RESULT
  // ============================================================

  Future<void> _selectPrediction(
    _PlacePrediction prediction,
  ) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
    });

    try {
      final uri = Uri.parse(
        'https://places.googleapis.com/v1/places/${prediction.placeId}',
      );

      final response = await http.get(
        uri,
        headers: {
          'X-Goog-Api-Key': _googleApiKey,

          // We only need coordinates and address information.
          'X-Goog-FieldMask':
              'location,displayName,formattedAddress',
        },
      );

      if (response.statusCode != 200) {
        print(
          'Place Details error: '
          '${response.statusCode} ${response.body}',
        );

        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }

        return;
      }

      final data = jsonDecode(response.body);

      final location = data['location'];
      final formattedAddress = data['formattedAddress']?.toString();

      if (location == null) {
        _showLocationMessage(
          'Unable to find the location coordinates.',
        );

        return;
      }

      final latitude =
          (location['latitude'] as num).toDouble();

      final longitude =
          (location['longitude'] as num).toDouble();

      final newLocation = LatLng(
        latitude,
        longitude,
      );

      if (!mounted) return;

      final displayName =
          data['displayName']?['text']?.toString();

      setState(() {
        _selectedLocation = newLocation;
        _selectedPlaceName =
            displayName != null && formattedAddress != null
                ? '$displayName, $formattedAddress'
                : displayName ??
                    formattedAddress ??
                    prediction.description;
        _searchController.text = prediction.mainText;
        _predictions = [];
        _isSearching = false;
      });

      // Generate a new session for the next search.
      _sessionToken =
          DateTime.now().millisecondsSinceEpoch.toString();

      // Move map to selected place.
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newLocation,
            zoom: 17,
          ),
        ),
      );
    } catch (e) {
      print('Error selecting place: $e');

      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      _showLocationMessage(
        'Unable to select this location.',
      );
    }
  }

  // ============================================================
  // MAP TAP
  // ============================================================

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
       _selectedPlaceName = null; 
      // Clear search because user manually selected a point.
      _searchController.clear();
      _predictions = [];
    });
  }

  // ============================================================
  // MARKER DRAGGED
  // ============================================================

  void _onMarkerDragEnd(LatLng position) {
    setState(() {
      _selectedLocation = position;
       _selectedPlaceName = null; 
      _searchController.clear();
      _predictions = [];
    });
  }

  // ============================================================
  // CURRENT LOCATION BUTTON
  // ============================================================

  Future<void> _goToCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Location permission is required.',
        );
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation = currentLocation;
        _searchController.clear();
        _predictions = [];
      });

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 17,
          ),
        ),
      );
    } catch (e) {
      print('Error moving to current location: $e');

      _showLocationMessage(
        'Unable to get your current location.',
      );
    }
  }

  // ============================================================
  // ERROR / INFO MESSAGE
  // ============================================================

  void _showLocationMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          // ========================================================
          // GOOGLE MAP
          // ========================================================

          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 16,
            ),

            onMapCreated: (controller) {
              _mapController = controller;
            },

            markers: {
              Marker(
                markerId:
                    const MarkerId('selected-location'),

                position: _selectedLocation,

                draggable: true,

                onDragEnd: _onMarkerDragEnd,
              ),
            },

            onTap: _onMapTapped,

            myLocationEnabled: true,
            myLocationButtonEnabled: false,

            zoomControlsEnabled: false,

            mapToolbarEnabled: false,
          ),

          // ========================================================
          // SEARCH BAR
          // ========================================================

          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,

                    onChanged: _onSearchChanged,

                    textInputAction:
                        TextInputAction.search,

                    decoration: InputDecoration(
                      hintText:
                          'Search for a location',

                      prefixIcon: const Icon(
                        Icons.search,
                      ),

                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                ),
                                onPressed: () {
                                  _searchController.clear();

                                  setState(() {
                                    _predictions = [];
                                  });
                                },
                              )
                              : null,

                      filled: true,

                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide:
                            BorderSide.none,
                      ),

                      contentPadding:
                          const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                    ),
                  ),
                ),

                // ==================================================
                // SEARCH RESULTS
                // ==================================================

                if (_predictions.isNotEmpty)
                  Container(
                    margin:
                        const EdgeInsets.only(top: 6),

                    constraints:
                        const BoxConstraints(
                      maxHeight: 280,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          spreadRadius: 1,
                          color:
                              Colors.black.withOpacity(
                            0.15,
                          ),
                        ),
                      ],
                    ),

                    child: ListView.separated(
                      shrinkWrap: true,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 4,
                      ),

                      itemCount:
                          _predictions.length,

                      separatorBuilder:
                          (_, __) =>
                              const Divider(
                        height: 1,
                      ),

                      itemBuilder:
                          (context, index) {
                        final prediction =
                            _predictions[index];

                        return ListTile(
                          dense: true,

                          leading: const Icon(
                            Icons.location_on_outlined,
                            color:
                                AppColors.primary,
                          ),

                          title: Text(
                            prediction.mainText,

                            maxLines: 1,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          subtitle:
                              prediction
                                      .secondaryText
                                      .isNotEmpty
                                  ? Text(
                                    prediction
                                        .secondaryText,

                                    maxLines: 1,

                                    overflow:
                                        TextOverflow
                                            .ellipsis,

                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                    ),
                                  )
                                  : null,

                          onTap: () =>
                              _selectPrediction(
                            prediction,
                          ),
                        );
                      },
                    ),
                  ),

                if (_isSearching)
                  const Padding(
                    padding:
                        EdgeInsets.only(top: 8),
                    child: Align(
                      alignment:
                          Alignment.centerRight,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ========================================================
          // CURRENT LOCATION BUTTON
          // ========================================================

          Positioned(
            right: 16,
            bottom: 125,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                customBorder:
                    const CircleBorder(),

                onTap:
                    _goToCurrentLocation,

                child: const Padding(
                  padding:
                      EdgeInsets.all(12),

                  child: Icon(
                    Icons.my_location,
                    color:
                        AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // ========================================================
          // GOOGLE MAPS / PLACES ATTRIBUTION
          // ========================================================

          Positioned(
            left: 16,
            bottom: 105,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),

              color: Colors.white
                  .withOpacity(0.85),

              child: const Text(
                'Powered by Google',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          // ========================================================
          // CONFIRM BUTTON
          // ========================================================

          Positioned(
            left: 60,
            right: 60,
            bottom: 30,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoadingLocation
                      ? null
                      : () {
                          Navigator.of(context).pop(
                            LocationPickerResult(
                            location: _selectedLocation,
                            name: _selectedPlaceName,
                            ),
                          );
                        },

                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ===========================================================================
// PLACE PREDICTION MODEL
// ===========================================================================

class _PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const _PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

class LocationPickerResult {
  final LatLng location;
  final String? name;

  const LocationPickerResult({
    required this.location,
    this.name,
  });
}