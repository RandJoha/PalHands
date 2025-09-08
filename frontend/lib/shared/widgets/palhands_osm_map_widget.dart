import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/map_models.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../services/map_service.dart';

class PalHandsOsmMapWidget extends StatefulWidget {
  final ll.LatLng? initialLocation;
  final MapFilters? initialFilters;
  final Function(MapMarker)? onMarkerTap;

  const PalHandsOsmMapWidget({
    super.key,
    this.initialLocation,
    this.initialFilters,
    this.onMarkerTap,
  });

  @override
  State<PalHandsOsmMapWidget> createState() => _PalHandsOsmMapWidgetState();
}

class _PalHandsOsmMapWidgetState extends State<PalHandsOsmMapWidget> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  List<MapMarker> _markers = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final center = widget.initialLocation ?? ll.LatLng(31.9522, 35.2332);
      final latDelta = 0.1; // ~11km
      final lngDelta = 0.1;
      final bounds = MapBounds(
        northeast: llToGm(ll.LatLng(center.latitude + latDelta / 2, center.longitude + lngDelta / 2)),
        southwest: llToGm(ll.LatLng(center.latitude - latDelta / 2, center.longitude - lngDelta / 2)),
      );
      final markers = await _mapService.getProvidersInBounds(
        bounds: bounds,
        filters: widget.initialFilters,
      );
      if (!mounted) return;
      setState(() {
        _markers = markers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialLocation ?? ll.LatLng(31.9522, 35.2332);
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
            onTap: (_, __) {},
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.palhands.app',
            ),
            MarkerLayer(
              markers: _markers.map((m) => _buildMarker(m)).toList(),
            ),
          ],
        ),
        if (_loading)
          Container(
            color: Colors.white.withOpacity(0.6),
            child: const Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Material(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
      ],
    );
  }

  Marker _buildMarker(MapMarker m) {
    final pos = ll.LatLng(m.position.latitude, m.position.longitude);
    // Use a uniform color for all providers (as requested)
    final color = m.type == MapMarkerType.provider
        ? Colors.green
        : (m.type == MapMarkerType.client ? Colors.green : Colors.green);
    return Marker(
      point: pos,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => widget.onMarkerTap?.call(m),
        child: Icon(Icons.location_pin, color: color, size: 34),
      ),
    );
  }

  // Helper to convert latlong2 -> google_maps LatLng used by MapBounds
  static LatLng llToGm(ll.LatLng p) => LatLng(p.latitude, p.longitude);
}


