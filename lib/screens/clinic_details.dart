import 'package:flutter/material.dart';
import '../models/vet_clinic.dart';


class ClinicDetailsPage extends StatelessWidget {

  final VetClinic clinic;
  final Map<String, dynamic> details;


  const ClinicDetailsPage({
    super.key,
    required this.clinic,
    required this.details,
  });


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(clinic.clinicName),
      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [


            Text(
              clinic.clinicName,

              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 15),


            Row(
              children: [

                const Icon(Icons.location_on),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    clinic.address,
                  ),
                ),

              ],
            ),



            const SizedBox(height: 15),



            Row(
              children: [

                const Icon(Icons.phone),

                const SizedBox(width: 8),


                Text(
                  details["formatted_phone_number"]
                  ?? "No phone number",
                ),

              ],
            ),



            const SizedBox(height: 15),



            const Text(
              "Operating Hours",

              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),



            const SizedBox(height: 8),



            if(details["opening_hours"] != null)

              ...List<String>.from(
                details["opening_hours"]["weekday_text"]
              )
              .map(
                (hour) => Text(hour),
              ),


          ],
        ),
      ),
    );
  }
}