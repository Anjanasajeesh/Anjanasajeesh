import 'package:car_booking_app/IntercityConfirmationScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntercityTripOptionsScreen extends StatefulWidget {
  final String destination;
  final String pickupDateTime;

  const IntercityTripOptionsScreen({
    super.key,
    required this.destination,
    required this.pickupDateTime,
  });

  @override
  State<IntercityTripOptionsScreen> createState() =>
      _IntercityTripOptionsScreenState();
}

class _IntercityTripOptionsScreenState
    extends State<IntercityTripOptionsScreen> {
  // Dummy intercity vehicle options data (replace with your actual data fetching)
  final List<Map<String, dynamic>> _intercityOptions = [
    {
      'name': 'Sedan',
      'price': 1500,
      'operator': 'KSRTC',
      'from': 'Kochi Main Bus Stand',
      'to': 'Alleppey Bus Stand',
      'estTime': 'Est. Time: 3 hrs',
    },
    {
      'name': 'SUV',
      'price': 2500,
      'operator': 'Private Travels',
      'from': 'Kochi Main Bus Stand',
      'to': 'Alleppey Bus Stand',
      'estTime': 'Est. Time: 4 hrs 30 mins',
    },
    {
      'name': 'Bus',
      'price': 800,
      'operator': 'ABC Transports',
      'from': 'Kochi Main Bus Stand',
      'to': 'Alleppey Bus Stand',
      'estTime': 'Est. Time: 4 hrs 30 mins',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Intercity Trips to ${widget.destination}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView.builder(
        itemCount: _intercityOptions.length,
        itemBuilder: (context, index) {
          final option = _intercityOptions[index];
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
                    'Price: ₹${option['price']}',
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                  Text(
                    'Operator: ${option['operator']}',
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'From: ${option['from']}',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'To: ${option['to']}',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option['estTime'],
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => IntercityConfirmationScreen(
                                    tripDetails: option,
                                    destination: widget.destination,
                                    pickupDateTime: widget.pickupDateTime,
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
