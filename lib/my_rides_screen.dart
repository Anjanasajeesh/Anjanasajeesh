import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  // Dummy data for rides (replace with your actual data fetching)
  late final List<Map<String, dynamic>> upcomingRides;
  late final List<Map<String, dynamic>> completedRides;
  late final List<Map<String, dynamic>> cancelledRides;

  @override
  void initState() {
    super.initState();
    upcomingRides = [
      {
        'date': 'Today, 10:30 AM',
        'mapImage': 'assets/map_upcoming.png', // Replace with actual image path
        'service': 'JUBERGO',
        'pickup': 'Kochi - MG Road',
        'dropoff': 'Fort Kochi',
        'price': '\$28.75',
      },
      {
        'date': 'May 20, 2025, 09:00 AM',
        'mapImage':
            'assets/map_upcoming_2.png', // Replace with actual image path
        'service': 'JUBERCITY',
        'pickup': 'Edappally',
        'dropoff': 'Vyttila',
        'price': '\$15.20',
      },
    ];

    completedRides = [
      {
        'date': 'May 16, 2025, 07:45 PM',
        'mapImage':
            'assets/map_completed_1.png', // Replace with actual image path
        'service': 'JUBERAUTO',
        'pickup': 'Kakkanad',
        'dropoff': 'Palarivattom',
        'price': '\$8.50',
      },
      {
        'date': 'May 15, 2025, 02:00 PM',
        'mapImage':
            'assets/map_completed_2.png', // Replace with actual image path
        'service': 'JUBERGO',
        'pickup': 'Aluva',
        'dropoff': 'Angamaly',
        'price': '\$42.00',
      },
    ];

    cancelledRides = [
      {
        'date': 'May 14, 2025, 05:00 PM',
        'service': 'JUBERX',
        'pickup': 'Tripunithura',
        'dropoff': 'InfoPark',
        'reason': 'Passenger cancelled',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My rides',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'UPCOMING'),
              Tab(text: 'COMPLETED'),
              Tab(text: 'CANCELLED'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRidesList(upcomingRides),
            _buildRidesList(completedRides),
            _buildCancelledRidesList(cancelledRides),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(List<Map<String, dynamic>> rides) {
    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride['date'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Replace with actual map widget or image
                Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Map Placeholder'),
                  ), // Use Image.asset(ride['mapImage'])
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['service'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${ride['pickup']} - ${ride['dropoff']}',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'PRICE',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        Text(
                          ride['price'],
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCancelledRidesList(List<Map<String, dynamic>> rides) {
    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride['date'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${ride['pickup']} - ${ride['dropoff']}',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cancelled Reason:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Text(
                  ride['reason'],
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
