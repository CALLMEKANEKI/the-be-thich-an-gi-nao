import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../widgets/osm_map_widget.dart';

class MapPocScreen extends StatefulWidget {
  const MapPocScreen({super.key});

  @override
  State<MapPocScreen> createState() => _MapPocScreenState();
}

class _MapPocScreenState extends State<MapPocScreen> {
  double _lat = LocationService.defaultLatitude;
  double _lng = LocationService.defaultLongitude;
  bool _loadingLocation = true;
  String _status = 'Đang lấy vị trí GPS...';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final Position? pos = await LocationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        if (pos != null) {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _status = 'Vị trí hiện tại: (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})';
        } else {
          _status = 'Dùng toạ độ mặc định (Quận 1, TP.HCM): (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})';
        }
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map & GPS PoC (OpenStreetMap)'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Row(
              children: [
                if (_loadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.location_pin, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: OsmMapWidget(
              centerLatitude: _lat,
              centerLongitude: _lng,
            ),
          ),
        ],
      ),
    );
  }
}
