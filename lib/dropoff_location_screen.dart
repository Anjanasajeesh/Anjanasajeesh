import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DropoffLocationScreen extends StatefulWidget {
  const DropoffLocationScreen({super.key});

  @override
  State<DropoffLocationScreen> createState() => _DropoffLocationScreenState();
}

class _DropoffLocationScreenState extends State<DropoffLocationScreen> {
  // Example list of locations
  final List<String> _locations = [
    'Kochi Airport',
    'Ernakulam Junction Railway Station',
    'Fort Kochi',
    'Marine Drive',
    'MG Road, Ernakulam',
    'Infopark Kochi',
    'Cochin Special Economic Zone',
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
        title: Text('Select Dropoff Location', style: GoogleFonts.poppins()),
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
