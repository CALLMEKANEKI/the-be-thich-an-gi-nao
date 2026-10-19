import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/nearby_place.dart';
import '../provider/places_provider.dart';
import '../services/deeplink_service.dart';
import '../widgets/osm_map_widget.dart';

class RestaurantResultScreen extends StatefulWidget {
  final String dishName;
  final double latitude;
  final double longitude;

  const RestaurantResultScreen({
    super.key,
    required this.dishName,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<RestaurantResultScreen> createState() => _RestaurantResultScreenState();
}

class _RestaurantResultScreenState extends State<RestaurantResultScreen> {
  NearbyPlace? _selectedPlace;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quán Ăn: ${widget.dishName} 🛵'),
      ),
      body: Consumer<PlacesProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            PlacesStatus.idle || PlacesStatus.loading => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tìm quán bán "${widget.dishName}" gần bạn...',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            PlacesStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage ?? 'Không thể tải danh sách quán ăn',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          provider.prefetch(
                            dishName: widget.dishName,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                          );
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            PlacesStatus.success => _buildPlacesContent(provider.places),
          };
        },
      ),
    );
  }

  Widget _buildPlacesContent(List<NearbyPlace> places) {
    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.store_mall_directory_outlined, size: 56, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Không tìm thấy quán gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Thử mở rộng bán kính hoặc chọn món ăn khác nhé!',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Phần trên: Bản đồ OpenStreetMap nhúng
        SizedBox(
          height: 240,
          child: OsmMapWidget(
            centerLatitude: widget.latitude,
            centerLongitude: widget.longitude,
            places: places,
            selectedPlace: _selectedPlace,
            onPlaceSelected: (place) {
              setState(() {
                _selectedPlace = place;
              });
            },
          ),
        ),

        // Header thông báo số quán tìm thấy
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tìm thấy ${places.length} quán lân cận',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Text(
                'Bán kính: ~3 km',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Phần dưới: Danh sách quán
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final place = places[index];
              final isSelected = _selectedPlace?.name == place.name;

              return Card(
                elevation: isSelected ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDistance(place.distance),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.25,
                        ),
                      ),
                      // Ẩn rating khi rating == 0 theo quy định Handoff Guide
                      if (place.rating > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Nút "Chỉ đường"
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            side: const BorderSide(color: Color(0xFF1E88E5)),
                            foregroundColor: const Color(0xFF1E88E5),
                          ),
                          onPressed: () {
                            if (place.map_url.isNotEmpty) {
                              DeeplinkService.openUrl(place.map_url);
                            } else {
                              DeeplinkService.openMapDirections(
                                place.latitude,
                                place.longitude,
                              );
                            }
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text(
                            'Chỉ đường',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
