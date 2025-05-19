import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PickupLocationScreen extends StatefulWidget {
  const PickupLocationScreen({super.key});

  @override
  State<PickupLocationScreen> createState() => _PickupLocationScreenState();
}

class _PickupLocationScreenState extends State<PickupLocationScreen> {
  // Example list of locations
  final List<String> _locations = [
    'Kochi Airport',
    'Ernakulam Junction Railway Station',
    'Fort Kochi',
    'Marine Drive',
    'MG Road, Ernakulam',
  ];
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filteredLocations = _locations;
    _searchController.addListener(_filterLocations);
  }

  void _filterLocations() {
    setState(() {
      _filteredLocations =
          _locations
              .where(
                (location) => location.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Pickup Location', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search location',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final location = _filteredLocations[index];
                return ListTile(
                  title: Text(location, style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context, location);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
