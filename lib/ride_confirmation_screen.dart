import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RideConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> rideDetails;
  final String pickup;
  final String dropoff;

  const RideConfirmationScreen({
    super.key,
    required this.rideDetails,
    required this.pickup,
    required this.dropoff,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirm Ride', style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ride Details:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vehicle: ${rideDetails['name']}',
              style: GoogleFonts.poppins(),
            ),
            Text(
              'Price: \$${rideDetails['price']}',
              style: GoogleFonts.poppins(),
            ),
            Text(
              'Estimated Time: ${rideDetails['estTime']}',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Text(
              'Pickup Location:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(pickup, style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            Text(
              'Dropoff Location:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(dropoff, style: GoogleFonts.poppins()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Implement your booking logic here
                  print('Booking confirmed!');
                  // You might navigate to a booking confirmation screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Confirm Booking', style: GoogleFonts.poppins()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
