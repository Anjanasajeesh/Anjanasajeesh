// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Assuming this file exists and is correctly implemented
import 'package:car_booking_app/intercity_trip_options_screen.dart';

class PlanIntercityTripScreen extends StatefulWidget {
  final String destination;

  const PlanIntercityTripScreen({super.key, required this.destination});

  @override
  State<PlanIntercityTripScreen> createState() =>
      _PlanIntercityTripScreenState();
}

class _PlanIntercityTripScreenState extends State<PlanIntercityTripScreen> {
  TextEditingController destinationController = TextEditingController();
  TextEditingController pickupDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    destinationController.text = widget.destination;
  }

  Future<void> _selectDateAndTime(BuildContext context) async {
    final DateTime? pickedDateTime = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (pickedDateTime != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final formattedDateTime = DateTime(
          pickedDateTime.year,
          pickedDateTime.month,
          pickedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        pickupDateController.text =
            "${formattedDateTime.day}-${formattedDateTime.month}-${formattedDateTime.year} ${pickedTime.format(context)}";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Plan your intercity trip',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.card_giftcard, color: Colors.green),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Get 5% OFF up to ₹500 on your first trip!',
                      style: GoogleFonts.poppins(color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: destinationController,
              decoration: InputDecoration(
                labelText: 'Enter destination',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.poppins(),
              ),
              style: GoogleFonts.poppins(),
              readOnly: true,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: pickupDateController,
              decoration: InputDecoration(
                labelText: 'Pick-up date and time',
                prefixIcon: const Icon(Icons.upload_file),
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.poppins(),
              ),
              style: GoogleFonts.poppins(),
              readOnly: true,
              onTap: () => _selectDateAndTime(context),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final String destination = destinationController.text;
                  final String pickupDateTime = pickupDateController.text;

                  if (destination.isNotEmpty && pickupDateTime.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => IntercityTripOptionsScreen(
                              destination: destination,
                              pickupDateTime: pickupDateTime,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select a destination and pick-up date/time',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Find trips',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Assured Intercity\nrides!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Kochi to Alleppey &\nMunnar starting at\naffordable fares with 24*7\nsupport!',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
