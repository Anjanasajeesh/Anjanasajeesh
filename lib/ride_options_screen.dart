import 'package:car_booking_app/ride_confirmation_screen.dart'; // Import the confirmation screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RideOptionsScreen extends StatelessWidget {
  final String pickup;
  final String dropoff;

  const RideOptionsScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ride Options', style: GoogleFonts.poppins()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: 5, // Replace with the actual number of ride options
        itemBuilder: (context, index) {
          // Replace this dummy data with your actual ride option data
          final String serviceType = index == 0 ? 'JUBER X' : 'JUBER Go';
          final double price = index == 0 ? 22.50 : 18.00;
          final String pickupTime = 'Today, 10:${45 + index} AM';
          final Map<String, dynamic> rideDetails = {
            'serviceType': serviceType,
            'price': price,
            'pickupTime': pickupTime,
            // Add other relevant details here
          };

          return Card(
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickupTime,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8.0),
                  // Map Snippet Placeholder
                  Container(
                    height: 80.0,
                    width: double.infinity,
                    color: Colors.grey[200], // Replace with actual map or image
                    child: Center(
                      child: Text(
                        'Map Placeholder',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    serviceType,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          pickup,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.flag, color: Colors.red, size: 16),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          dropoff,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // You might add other details here, like estimated time
                      Text(
                        'Est. 15 min',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$$price',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to the RideConfirmationScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RideConfirmationScreen(
                                  rideDetails: rideDetails,
                                  pickup: pickup,
                                  dropoff: dropoff,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Select',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
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
