import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingSuccessfulScreen extends StatelessWidget {
  final Map<String, dynamic>? bookingDetails;

  const BookingSuccessfulScreen({super.key, this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Successful', style: GoogleFonts.poppins()),
        automaticallyImplyLeading: false, // To remove the back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100.0,
              ),
              const SizedBox(height: 32.0),
              Text(
                'Booking Successful!',
                style: GoogleFonts.poppins(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              if (bookingDetails != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bookingDetails!['bookingId'] != null)
                      Text(
                        'Booking ID: ${bookingDetails!['bookingId']}',
                        style: GoogleFonts.poppins(),
                      ),
                    if (bookingDetails!['vehicleType'] != null)
                      Text(
                        'Vehicle: ${bookingDetails!['vehicleType']}',
                        style: GoogleFonts.poppins(),
                      ),
                    if (bookingDetails!['pickupLocation'] != null)
                      Text(
                        'Pickup: ${bookingDetails!['pickupLocation']}',
                        style: GoogleFonts.poppins(),
                      ),
                    if (bookingDetails!['pickupTime'] != null)
                      Text(
                        'Time: ${bookingDetails!['pickupTime']}',
                        style: GoogleFonts.poppins(),
                      ),
                    if (bookingDetails!['dropoffLocation'] != null)
                      Text(
                        'Dropoff: ${bookingDetails!['dropoffLocation']}',
                        style: GoogleFonts.poppins(),
                      ),
                    if (bookingDetails!['totalFare'] != null)
                      Text(
                        'Total Fare: ₹${bookingDetails!['totalFare']}',
                        style: GoogleFonts.poppins(),
                      ),
                    if (bookingDetails!['paymentMethod'] != null)
                      Text(
                        'Paid with: ${bookingDetails!['paymentMethod']}',
                        style: GoogleFonts.poppins(),
                      ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to the home screen or bookings screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  ); // Example: Go to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Back to Home', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
