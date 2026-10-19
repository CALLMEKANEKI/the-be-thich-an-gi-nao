import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_theme.dart';
import '../services/deeplink_service.dart';
import '../services/location_service.dart';
import '../widgets/osm_map_widget.dart';

class MapPocScreen extends StatefulWidget {
  const MapPocScreen({super.key});

  @override
  State<MapPocScreen> createState() => _MapPocScreenState();
}

class _MapPocScreenState extends State<MapPocScreen> {
  double _userLat = LocationService.defaultLatitude;
  double _userLng = LocationService.defaultLongitude;

  @override
  void initState() {
    super.initState();
    _currentDestName = widget.destinationName ?? 'Bún Bò Huế O Oanh';
    _currentDestLat = widget.destinationLat ?? _userLat + 0.005;
    _currentDestLng = widget.destinationLng ?? _userLng + 0.005;
    _currentAddress = widget.restaurantAddress ?? 'Số 55 Hoàng Quốc Việt, Cầu Giấy, Hà Nội';
    _currentRating = widget.rating ?? 4.8;

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

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _recenterOnUser() async {
    await _initLocation();
    _mapController.move(LatLng(_userLat, _userLng), 15.5);
  }

  @override
  Widget build(BuildContext context) {
    final destName = widget.destinationName ?? 'Bún Bò Huế O Oanh';
    final destLat = widget.destinationLat ?? _userLat + 0.005;
    final destLng = widget.destinationLng ?? _userLng + 0.005;
    final address = widget.restaurantAddress ?? 'Số 55 Hoàng Quốc Việt, Cầu Giấy, Hà Nội';
    final rating = widget.rating ?? 4.8;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full Screen Interactive OpenStreetMap Canvas
            Positioned.fill(
              child: OsmMapWidget(
                centerLatitude: destLat,
                centerLongitude: destLng,
              ),
            ),

            // 2. Top Floating Destination Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceContainer,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.near_me, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ĐIỂM ĐẾN ĐÃ CHỌN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            destName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, size: 20),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceContainerLow,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Right Map Controls (Zoom / Location)
            Positioned(
              right: 16,
              top: 90,
              child: Column(
                children: [
                  _buildFloatingMapButton(
                    icon: Icons.layers,
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {},
                        ),
                        Container(
                          width: 24,
                          height: 1,
                          color: AppTheme.surfaceContainer,
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFloatingMapButton(
                    icon: Icons.my_location,
                    color: AppTheme.secondaryMint,
                    onTap: _initLocation,
                  ),
                ],
              ),
            ),

            // 4. Bottom Selected Restaurant Details Card
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x25000000),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryFixed,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: AppTheme.tertiaryAmber),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '0.8 km • 5 phút đi xe',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              DeeplinkService.openMap(
                                latitude: destLat,
                                longitude: destLng,
                                placeName: destName,
                              );
                            },
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text(
                              'CHỈ ĐƯỜNG NGAY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryContainer,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? AppTheme.onSurface, size: 20),
      ),
    );
  }
}
