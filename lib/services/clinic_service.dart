import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vet_clinic.dart';

class ClinicService {

  final String apiKey = "AIzaSyD3pyhrWt673U3iiK4WmRiyWdN3THCZdPc";

  Future<List<VetClinic>> searchNearbyClinics(
      double latitude,
      double longitude,
      ) async {

    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=$latitude,$longitude"
        "&radius=5000"
        "&keyword=veterinary%20clinic"
        "&key=$apiKey";


    final response = await http.get(Uri.parse(url));

    final data = json.decode(response.body);


    List<VetClinic> clinics = [];


    for (var place in data["results"]) {

      clinics.add(
        VetClinic(
          clinicId: place["place_id"],
          clinicName: place["name"],
          city: place["vicinity"].split(",").last.trim(),
          address: place["vicinity"],
          //state: "", 
          phoneNumber: "", 
          operatingHours: "",
          services: [], 
          latitude: place["geometry"]["location"]["lat"],
          longitude: place["geometry"]["location"]["lng"],
        ),
      );

    }

    return clinics;
  }

   Future<List<VetClinic>> searchClinics(
    String query,
  ) async {


    final url =
        "https://maps.googleapis.com/maps/api/place/textsearch/json"
        "?query=$query veterinary clinic"
        "&key=$apiKey";


    final response = await http.get(
      Uri.parse(url),
    );


    final data = json.decode(response.body);


    List<VetClinic> clinics = [];


    for (var place in data["results"]) {


      clinics.add(

        VetClinic(

          clinicId:
              place["place_id"],


          clinicName:
              place["name"],


          address:
              place["formatted_address"] ??
              place["vicinity"],


          city:
              "",


          phoneNumber:
              "",


          operatingHours:
              "",


          services:
              [],


          latitude:
              place["geometry"]["location"]["lat"],


          longitude:
              place["geometry"]["location"]["lng"],

        ),

      );

    }


    return clinics;

  }

  //to get clinic details by place_id
  Future<Map<String, dynamic>> getClinicDetails(String placeId) async {

  final url =
      "https://maps.googleapis.com/maps/api/place/details/json"
      "?place_id=$placeId"
      "&fields=name,formatted_phone_number,opening_hours,website"
      "&key=$apiKey";


  final response = await http.get(
    Uri.parse(url),
  );


  final data = json.decode(response.body);


  if (data["status"] != "OK") {
    throw Exception("Failed to get clinic details");
  }


  return data["result"];

}

}


