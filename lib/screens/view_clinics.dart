import 'package:flutter/material.dart';
//import '../../app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location.dart';
import '../models/vet_clinic.dart';
import '../services/clinic_service.dart';

class ViewClinic extends StatefulWidget {
  const ViewClinic({super.key});

  @override
  State<ViewClinic> createState() => _ViewClinicState();
}

class _ViewClinicState extends State<ViewClinic> {
  GoogleMapController? mapController;

  final LocationService locationService = LocationService();

  LatLng currentLocation = const LatLng(3.1390, 101.6869); // Kuala Lumpur

  bool loading = true;

  Set<Marker> markers = {};

  List<VetClinic> clinics = []; // List to hold nearby clinics

  VetClinic? selectedClinic; // Variable to hold the selected clinic

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  //GET LOCATIONNNN
  Future<void> getLocation() async {
    try {
      Position position = await locationService.determinePosition();

      debugPrint("Latitude: ${position.latitude}");
      debugPrint("Longitude: ${position.longitude}");

      currentLocation = LatLng(position.latitude, position.longitude);

      clinics = await ClinicService().searchNearbyClinics(
        position.latitude,
        position.longitude,
      );

      if(clinics.isNotEmpty) {
        selectedClinic = clinics.first; // Set the first clinic as selected by default
      }

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

            onTap: () {
              setState(() {
                selectedClinic = clinic; // Set the selected clinic when marker is tapped
              });
            },
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

      setState(() {
        loading = false;
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

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

          //clinic card
          Positioned(
            bottom: 20,
            left: 60,
            child: SizedBox(width: 280, child: _buildClinicCard()),
          ),
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
        onSubmitted: (value) {
          // Implement search functionality here
        },
      ),
    );
  }

  Widget _buildClinicCard() {
    if (clinics.isEmpty) {
      return const SizedBox();
    }

    final clinic = selectedClinic ?? clinics.first;
    

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black26,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clinic.clinicName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 4),

          Text(
            clinic.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to clinic details
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(85, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Details", style: TextStyle(fontSize: 12)),
              ),

              const SizedBox(width: 8),

              ElevatedButton(
                onPressed: () {
                  // TODO: Open Google Maps directions
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(90, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Direction", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
