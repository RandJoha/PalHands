import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_models.dart';
import 'palhands_unified_map_widget.dart';

/// Example usage of the unified map widget
/// This shows how to integrate the OSM-based map in your pages
class MapUsageExample extends StatelessWidget {
  const MapUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Example'),
      ),
      body: Column(
        children: [
          // Example 1: Basic map with default settings
          Expanded(
            flex: 1,
            child: PalHandsUnifiedMapWidget(
              initialLocation: const LatLng(31.9522, 35.2332), // Ramallah
              onMarkerTap: (marker) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on ${marker.name}')),
                );
              },
            ),
          ),
          
          const Divider(),
          
          // Example 2: Map with filters
          Expanded(
            flex: 1,
            child: PalHandsUnifiedMapWidget(
              initialLocation: const LatLng(31.7683, 35.2137), // Jerusalem
              initialFilters: const MapFilters(
                category: 'cleaning',
                minRating: 4.0,
                isAvailable: true,
              ),
              showLocationToggle: true,
              onLocationChanged: (location) {
                print('Location changed to: ${location.latitude}, ${location.longitude}');
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Example of how to use the map in a category page
class CategoryPageWithMap extends StatefulWidget {
  final String category;
  
  const CategoryPageWithMap({
    super.key,
    required this.category,
  });

  @override
  State<CategoryPageWithMap> createState() => _CategoryPageWithMapState();
}

class _CategoryPageWithMapState extends State<CategoryPageWithMap> {
  bool _showMap = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Services'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap ? 'Show List' : 'Show Map',
          ),
        ],
      ),
      body: _showMap 
          ? PalHandsUnifiedMapWidget(
              initialFilters: MapFilters(
                category: widget.category,
                isAvailable: true,
              ),
              showLocationToggle: true,
            )
          : const Center(
              child: Text('Service list would go here'),
            ),
    );
  }
}
