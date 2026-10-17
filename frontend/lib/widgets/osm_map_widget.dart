import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/nearby_place.dart';

class OsmMapWidget extends StatelessWidget {
  final double centerLatitude;
  final double centerLongitude;
  final double initialZoom;
  final List<NearbyPlace> places;
  final NearbyPlace? selectedPlace;
  final ValueChanged<NearbyPlace>? onPlaceSelected;

  const OsmMapWidget({
    super.key,
    required this.centerLatitude,
    required this.centerLongitude,
    this.initialZoom = 14.5,
    this.places = const [],
    this.selectedPlace,
    this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // Marker vị trí người dùng
    markers.add(
      Marker(
        point: LatLng(centerLatitude, centerLongitude),
        width: 48,
        height: 48,
        child: const Icon(
          Icons.my_location,
          color: Colors.blueAccent,
          size: 32,
        ),
      ),
    );

    // Marker các quán ăn
    for (final place in places) {
      final isSelected = selectedPlace?.name == place.name;
      markers.add(
        Marker(
          point: LatLng(place.latitude, place.longitude),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => onPlaceSelected?.call(place),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.location_on,
                color: isSelected ? Colors.deepOrange : Colors.redAccent,
                size: isSelected ? 42 : 32,
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLatitude, centerLongitude),
        initialZoom: initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.frontend',
        ),
        MarkerLayer(markers: markers),
        const SimpleAttributionWidget(
          source: Text('© OpenStreetMap contributors'),
          alignment: Alignment.bottomRight,
        ),
      ],
    );
  }
}
