import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_methods_screen.dart'; // Import the payment methods screen

class IntercityConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> tripDetails;
  final String destination;
  final String?
  pickupDateTime; // Make it nullable as it might not always be there

  const IntercityConfirmationScreen({
    super.key,
    required this.tripDetails,
    required this.destination,
    this.pickupDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Intercity Trip', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm your ${tripDetails['name']} trip to $destination?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('From: ${tripDetails['from']}', style: GoogleFonts.poppins()),
            Text('To: ${tripDetails['to']}', style: GoogleFonts.poppins()),
            Text(
              'Price: ₹${tripDetails['price']}',
              style: GoogleFonts.poppins(),
            ),
            Text('${tripDetails['estTime']}', style: GoogleFonts.poppins()),
            Text(
              'Operator: ${tripDetails['operator']}',
              style: GoogleFonts.poppins(),
            ),
            if (pickupDateTime != null) // Conditionally show pickup date/time
              Text('Pick-up: $pickupDateTime', style: GoogleFonts.poppins()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to the PaymentMethodsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentMethodsScreen(),
                  ),
                );
                // ALTERNATIVE using named route (if defined in main.dart):
                // Navigator.pushNamed(context, '/payment_methods');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Confirm Booking', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}
