import 'package:flutter/material.dart';
//import '../../app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location.dart';
import '../models/vet_clinic.dart';
import '../services/clinic_service.dart';
import 'clinic_details.dart';

class ViewClinic extends StatefulWidget {
  const ViewClinic({super.key});

  @override
  State<ViewClinic> createState() => _ViewClinicState();
}

class _ViewClinicState extends State<ViewClinic> with WidgetsBindingObserver {
  //WidgetBindingObserver to refresh page after turn on location service

  GoogleMapController? mapController;

  final LocationService locationService = LocationService();

  LatLng currentLocation = const LatLng(3.1390, 101.6869); // Kuala Lumpur

  bool loading = true;

  bool _locationUnavailable = false;

  Set<Marker> markers = {};

  List<VetClinic> clinics = []; // List to hold nearby clinics

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    mapController?.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed &&
        _locationUnavailable) {
      getLocation();
    }
  }
  //GET LOCATIONNNN
  Future<void> getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _locationUnavailable = true;

        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        return;
      }
      Position position = await locationService.determinePosition();

      debugPrint("Latitude: ${position.latitude}");
      debugPrint("Longitude: ${position.longitude}");

      _locationUnavailable = false;

      currentLocation = LatLng(position.latitude, position.longitude);

      clinics = await ClinicService().searchNearbyClinics(
        position.latitude,
        position.longitude,
      );

      markers.clear();

      for (var clinic in clinics) {
        markers.add(
          Marker(
            markerId: MarkerId(clinic.clinicId),
            position: LatLng(clinic.latitude, clinic.longitude),
            infoWindow: InfoWindow(
              title: clinic.clinicName,
              snippet: clinic.address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: currentLocation,
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      );

      if (mounted) {
        setState(() {
          loading = false;
        });
      }

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );
    } catch (e) {
      debugPrint("Location error: $e");

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  } //end of get location


  Future<void> _refreshLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    getLocation();
  }

  //   Future<void> _showLocationDialog() async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(18),
  //         ),

  //         title: Row(
  //           children: const [
  //             Icon(
  //               Icons.location_off,
  //               color: Colors.orange,
  //             ),
  //             SizedBox(width: 8),
  //             Text("Location Required"),
  //           ],
  //         ),

  //         content: const Text(
  //           "PawPers needs access to your location to find nearby veterinary clinics.\n\n"
  //           "Please enable Location.",
  //         ),

  //         actions: [

  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: const Text("Cancel"),
  //           ),

  //           ElevatedButton.icon(
  //             icon: const Icon(Icons.settings),
  //             label: const Text("Open Settings"),

  //             onPressed: () async {

  //               Navigator.pop(context);

  //               await Geolocator.openLocationSettings();

  //             },
  //           ),

  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Clinics")),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 15,
            ),

            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,

            onMapCreated: (controller) {
              mapController = controller;
            },
          ),

          //seaerch bar
          Positioned(top: 20, left: 50, right: 50, child: _buildSearchBar()),

          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.75,

            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(12),

                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),

                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),

                child: _buildClinicList(scrollController),
              );
            },
          ),

          //clinic card
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: SizedBox(width: 280, child: _buildClinicList()),
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      //padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search for clinics",
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (value) async {
          final results = await ClinicService().searchClinics(
            value,
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
            );

          setState(() {
            clinics = results;
            markers.clear();

            for (var clinic in clinics) {
              markers.add(
                Marker(
                  markerId: MarkerId(clinic.clinicId),

                  position: LatLng(clinic.latitude, clinic.longitude),

                  infoWindow: InfoWindow(title: clinic.clinicName),
                ),
              );
            }
          });
          if (results.isNotEmpty) {
            mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(results.first.latitude, results.first.longitude),
                14,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildClinicList(ScrollController scrollController) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Nearby Clinics",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Text(
                "${clinics.length} found",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: clinics.length,

              itemBuilder: (context, index) {
                final clinic = clinics[index];

                return GestureDetector(
                  onTap: () {
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(clinic.latitude, clinic.longitude),
                        16,
                      ),
                    );
                  },

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Row(
                      children: [
                        Container(
                          height: 50,
                          width: 50,

                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                clinic.clinicName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                clinic.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () async {
                            final details = await ClinicService()
                                .getClinicDetails(clinic.clinicId);

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder:
                                    (context) => ClinicDetailsPage(
                                      clinic: clinic,
                                      details: details,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
