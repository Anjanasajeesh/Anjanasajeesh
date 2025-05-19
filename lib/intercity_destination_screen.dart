import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'plan_intercity_trip_screen.dart'; // Import the next screen

class IntercityDestinationScreen extends StatefulWidget {
  const IntercityDestinationScreen({super.key});

  @override
  State<IntercityDestinationScreen> createState() =>
      _IntercityDestinationScreenState();
}

class _IntercityDestinationScreenState
    extends State<IntercityDestinationScreen> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Where to?', style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Enter destination',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                final String destination = _destinationController.text;
                if (destination.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              PlanIntercityTripScreen(destination: destination),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a destination')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Search Intercity Trips',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
