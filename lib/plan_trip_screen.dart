// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ride_confirmation_screen.dart'; // Import the confirmation screen

class PlanTripScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;

  const PlanTripScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  // Dummy ride options data (replace with your actual data fetching)
  final List<Map<String, dynamic>> _rideOptions = [
    {
      'name': 'JUBER X',
      'latitude': 9.9909632,
      'longitude': 76.3133952,
      'location': 'kochi',
      'estTime': 'Est. 15 min',
      'price': 22.5,
    },
    {
      'name': 'JUBER Go',
      'latitude': 9.9909632,
      'longitude': 76.3133952,
      'location': 'kochi',
      'estTime': 'Est. 15 min',
      'price': 18.0,
    },
    {
      'name': 'JUBER XL',
      'latitude': 9.9909632,
      'longitude': 76.3133952,
      'location': 'kochi',
      'estTime': 'Est. 20 min',
      'price': 30.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ride Options',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView.builder(
        itemCount: _rideOptions.length,
        itemBuilder: (context, index) {
          final option = _rideOptions[index];
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitude: ${option['latitude']}, Longitude: ${option['longitude']}',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  Text(
                    option['location'],
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option['estTime'],
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${option['price']}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => RideConfirmationScreen(
                                    rideDetails: option,
                                    pickup: widget.pickup,
                                    dropoff: widget.dropoff,
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Select', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
