import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/nearby_place.dart';

class OsmMapWidget extends StatelessWidget {
  final double centerLatitude;
  final double centerLongitude;
  final double initialZoom;
  final double? userLatitude;
  final double? userLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? destinationName;
  final List<NearbyPlace> places;
  final NearbyPlace? selectedPlace;
  final ValueChanged<NearbyPlace>? onPlaceSelected;
  final MapController? mapController;

  const OsmMapWidget({
    super.key,
    required this.centerLatitude,
    required this.centerLongitude,
    this.initialZoom = 14.5,
    this.userLatitude,
    this.userLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationName,
    this.places = const [],
    this.selectedPlace,
    this.onPlaceSelected,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // 1. Marker vị trí người dùng (chấm xanh radar)
    final uLat = userLatitude ?? (destinationLatitude != null ? null : centerLatitude);
    final uLng = userLongitude ?? (destinationLongitude != null ? null : centerLongitude);
    if (uLat != null && uLng != null) {
      markers.add(
        Marker(
          point: LatLng(uLat, uLng),
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Marker điểm đến / Quán ăn đang chọn (ghim nổi bật màu cam)
    final dLat = destinationLatitude ?? centerLatitude;
    final dLng = destinationLongitude ?? centerLongitude;
    markers.add(
      Marker(
        point: LatLng(dLat, dLng),
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );

    // 3. Marker các quán ăn khác xung quanh
    for (final place in places) {
      final isSelected = selectedPlace?.name == place.name ||
          (place.latitude == dLat && place.longitude == dLng);
      if (isSelected) continue; // Đã vẽ ở marker điểm đến

      markers.add(
        Marker(
          point: LatLng(place.latitude, place.longitude),
          width: 38,
          height: 38,
          child: GestureDetector(
            onTap: () => onPlaceSelected?.call(place),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: mapController,
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
