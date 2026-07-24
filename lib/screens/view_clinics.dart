import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ViewClinic extends StatefulWidget {
  const ViewClinic({super.key});

  @override
  State<ViewClinic> createState() => _ViewClinicState();
}

class _ViewClinicState extends State<ViewClinic> {

 GoogleMapController? mapController;

  final LocationService locationService = LocationService();

  LatLng currentLocation =
      const LatLng(3.1390, 101.6869); // Kuala Lumpur

  bool loading = true;

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {

    try {

      Position position =
          await locationService.determinePosition();

      currentLocation =
          LatLng(position.latitude, position.longitude);

      markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: currentLocation,
          infoWindow: const InfoWindow(
            title: "You are here",
          ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {

    if (loading) {

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );

    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Nearby Clinics"),
      ),

      body: GoogleMap(

        initialCameraPosition:

            CameraPosition(
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

    );

  }


}
