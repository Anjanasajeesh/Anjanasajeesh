import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pickup_location_screen.dart';
import 'dropoff_location_screen.dart';
import 'plan_trip_screen.dart';

class PlanTripInputScreen extends StatefulWidget {
  const PlanTripInputScreen({super.key});

  @override
  State<PlanTripInputScreen> createState() => _PlanTripInputScreenState();
}

class _PlanTripInputScreenState extends State<PlanTripInputScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan your trip', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _pickupController,
              decoration: InputDecoration(
                labelText: 'Enter pick-up location',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              readOnly: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PickupLocationScreen(),
                  ),
                ).then((selectedLocation) {
                  if (selectedLocation != null) {
                    setState(() {
                      _pickupController.text = selectedLocation;
                    });
                  }
                });
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _dropoffController,
              decoration: InputDecoration(
                labelText: 'Where to?',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.where_to_vote_outlined),
              ),
              readOnly: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DropoffLocationScreen(),
                  ),
                ).then((selectedLocation) {
                  if (selectedLocation != null) {
                    setState(() {
                      _dropoffController.text = selectedLocation;
                    });
                  }
                });
              },
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                if (_pickupController.text.isNotEmpty &&
                    _dropoffController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PlanTripScreen(
                            pickup: _pickupController.text,
                            dropoff: _dropoffController.text,
                          ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select both pickup and dropoff locations',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Find Rides', style: GoogleFonts.poppins()),
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent locations',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8.0),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('Kochi Airport', style: GoogleFonts.poppins()),
              onTap: () {
                setState(() {
                  _pickupController.text =
                      'Kochi Airport'; // Example: Set pickup
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('Fort Kochi', style: GoogleFonts.poppins()),
              onTap: () {
                setState(() {
                  _dropoffController.text =
                      'Fort Kochi'; // Example: Set dropoff
                });
              },
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved places',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8.0),
            ListTile(
              leading: const Icon(Icons.star_border),
              title: Text('My Home', style: GoogleFonts.poppins()),
              onTap: () {
                setState(() {
                  _pickupController.text = 'My Home'; // Example: Set pickup
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border),
              title: Text('Office', style: GoogleFonts.poppins()),
              onTap: () {
                setState(() {
                  _dropoffController.text = 'Office'; // Example: Set dropoff
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
