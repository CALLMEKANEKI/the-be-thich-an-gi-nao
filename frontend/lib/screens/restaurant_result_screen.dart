import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/nearby_place.dart';
import '../provider/places_provider.dart';
import '../services/deeplink_service.dart';
import 'ingredients_screen.dart';
import 'map_poc_screen.dart';

/// Screen 05_Restaurant_Result, 05_Restaurant_Loading, 05_Restaurant_Error
/// from Stitch Project "Food Decider Flutter UI"
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
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Tất cả',
    'Gần nhất (< 1km)',
    'Đánh giá cao (4.5★)',
    'Đang mở cửa',
  ];

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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quán ăn gần bạn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: Consumer<PlacesProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            PlacesStatus.idle || PlacesStatus.loading => _buildLoadingState(),
            PlacesStatus.error => _buildErrorState(provider),
            PlacesStatus.success => provider.places.isEmpty
                ? _buildErrorState(provider)
                : _buildSuccessState(provider.places),
          };
        },
      ),
    );
  }

  // ==========================================
  // 1. SUCCESS STATE (05_Restaurant_Result)
  // ==========================================
  Widget _buildSuccessState(List<NearbyPlace> places) {
    return SafeArea(
      child: Column(
        children: [
          // Location context header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VỊ TRÍ TÌM KIẾM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Gần toạ độ: (${widget.latitude.toStringAsFixed(2)}, ${widget.longitude.toStringAsFixed(2)})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.gps_fixed, color: AppTheme.primary, size: 16),
                  ),
                ],
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedFilterIndex;
                return InkWell(
                  onTap: () => setState(() => _selectedFilterIndex = index),
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryFixed : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.onPrimaryFixed : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Restaurant List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final place = places[index];
                return _buildRestaurantCard(place);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(NearbyPlace place) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo thumbnail
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  image: place.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(place.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: place.imageUrl.isEmpty
                    ? const Icon(Icons.storefront, color: AppTheme.primary, size: 36)
                    : null,
              ),

              const SizedBox(width: 12),

              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiaryFixed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: AppTheme.tertiary),
                              const SizedBox(width: 2),
                              Text(
                                place.rating > 0 ? place.rating.toStringAsFixed(1) : '4.8',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onTertiaryFixed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatDistance(place.distanceMeters)} • ${place.openNow ? 'Đang mở cửa' : 'Mở cửa'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address,
                      style: const TextStyle(
                        fontSize: 12,
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

          const SizedBox(height: 12),

          // Action buttons: "Chỉ đường" and "Xem trên bản đồ"
          Row(
            children: [
              // Button 1: Chỉ đường qua Google Maps
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    DeeplinkService.openMap(
                      latitude: place.latitude,
                      longitude: place.longitude,
                      placeName: place.name,
                    );
                  },
                  icon: const Icon(Icons.near_me, size: 16),
                  label: const Text(
                    'Chỉ đường',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Button 2: Bản đồ OSM
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPocScreen(
                          destinationName: place.name,
                          destinationLat: place.latitude,
                          destinationLng: place.longitude,
                          restaurantAddress: place.address,
                          rating: place.rating,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 16, color: AppTheme.onSurface),
                  label: const Text(
                    'Xem bản đồ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. LOADING STATE (05_Restaurant_Loading)
  // ==========================================
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Radar Hero Animation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryFixed.withOpacity(0.4),
                  AppTheme.surfaceContainerLow,
                  AppTheme.surfaceContainerLowest,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Radar Rings
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryContainer.withOpacity(0.15),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.ramen_dining,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Đang tìm quán ngon quanh bạn...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đang quét các quán ${widget.dishName} chuẩn vị trong bán kính 3km từ vị trí của bé...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 14),

                // Linear indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const SizedBox(
                    width: 200,
                    height: 5,
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Safe Food Reassurance Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: AppTheme.onSecondaryContainer, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bộ lọc an toàn cho bé',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSecondaryContainer,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Đang lọc những quán đạt chuẩn vệ sinh và có đánh giá từ 4.5★ trở lên.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Skeleton Cards
          _buildSkeletonCard(),
          const SizedBox(height: 12),
          _buildSkeletonCard(),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. ERROR STATE (05_Restaurant_Error)
  // ==========================================
  Widget _buildErrorState(PlacesProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Location Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.near_me, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                const Text(
                  'Quanh vị trí của bạn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryFixed,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    'Đang tìm',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onTertiaryFixed,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Illustration Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10FF6B35),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Visual compass graphic
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFixed.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.explore_off, color: AppTheme.primary, size: 46),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Không tìm thấy quán quanh đây',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rất tiếc, chưa tìm thấy quán "${widget.dishName}" nào đang mở cửa ở gần vị trí hiện tại của bé, hoặc kết nối định vị GPS bị gián đoạn.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.explore, size: 14, color: AppTheme.secondaryMint),
                      SizedBox(width: 4),
                      Text(
                        'Mẹo: Thử mở rộng bán kính tìm kiếm',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Primary Button: THỬ LẠI
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                provider.searchPlaces(
                  dishName: widget.dishName,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0x4DFF6B35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'THỬ LẠI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_location_alt, size: 16),
                    label: const Text('ĐỔI VỊ TRÍ', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IngredientsScreen(dishName: widget.dishName),
                        ),
                      );
                    },
                    icon: const Icon(Icons.soup_kitchen, size: 16),
                    label: const Text('NẤU TẠI NHÀ', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryFixed,
                      foregroundColor: AppTheme.onPrimaryFixed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
