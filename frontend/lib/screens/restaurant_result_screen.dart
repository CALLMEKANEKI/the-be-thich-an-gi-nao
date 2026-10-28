import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PlacesProvider>();
      if (provider.status == PlacesStatus.idle ||
          provider.currentDishName != widget.dishName) {
        provider.prefetch(
          dishName: widget.dishName,
          latitude: widget.latitude,
          longitude: widget.longitude,
        );
      }
    });
  }

  void _onPlaceTap(NearbyPlace place, {bool moveMap = true}) {
    setState(() {
      _selectedPlace = place;
    });
    if (moveMap) {
      _mapController.move(LatLng(place.latitude, place.longitude), 15.5);
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _estimateDriveTime(double meters) {
    final minutes = (meters / 400).ceil();
    if (minutes <= 1) return '~1 phút xe máy';
    return '~$minutes phút xe máy';
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Đã sao chép địa chỉ quán ăn vào bộ nhớ tạm'),
          ],
        ),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primary),
                SizedBox(width: 6),
                Text(
                  'Quán Ăn Gần Bạn',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Món: ${widget.dishName}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh_rounded, size: 22, color: AppTheme.textSecondary),
            onPressed: () {
              context.read<PlacesProvider>().prefetch(
                    dishName: widget.dishName,
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                  );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<PlacesProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            PlacesStatus.idle || PlacesStatus.loading => _buildLoadingState(),
            PlacesStatus.error => _buildErrorState(provider),
            PlacesStatus.success => _buildPlacesContent(provider.places),
          };
        },
      ),
    );
  }

  // ==========================================
  // 1. LOADING STATE
  // ==========================================
  Widget _buildLoadingState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryFixed.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      backgroundColor: AppTheme.primaryFixed,
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                    ),
                    child: const Icon(
                      Icons.moped_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đang tìm quán bán "${widget.dishName}"...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang quét các địa điểm ẩm thực chất lượng trong bán kính ~3 km quanh toạ độ của bạn...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_searching_rounded, size: 16, color: AppTheme.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Đang tính toán khoảng cách & lộ trình',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. ERROR STATE
  // ==========================================
  Widget _buildErrorState(PlacesProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.wifi_off_rounded, size: 16, color: AppTheme.onPrimaryFixedVariant),
                  SizedBox(width: 6),
                  Text(
                    'KẾT NỐI BỊ GIÁN ĐOẠN',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.onPrimaryFixedVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải danh sách quán ăn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Hệ thống bản đồ tạm thời chưa phản hồi, vui lòng kiểm tra kết nối mạng và thử lại.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.prefetch(
                  dishName: widget.dishName,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Thử lại ngay',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. EMPTY STATE
  // ==========================================
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🔍', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 6),
                  Text(
                    'CHƯA CÓ DỮ LIỆU ĐỊA ĐIỂM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.onPrimaryFixed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainer,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 44,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy quán gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa tìm thấy quán nào ghi nhận phục vụ món "${widget.dishName}" trong phạm vi ~3 km quanh bạn. Bạn hãy thử mở rộng bán kính hoặc chọn món ăn khác nhé!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Quay lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<PlacesProvider>().prefetch(
                          dishName: widget.dishName,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                        );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tìm kiếm lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. MAIN CONTENT
  // ==========================================
  Widget _buildPlacesContent(List<NearbyPlace> places) {
    if (places.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Bản đồ vệ tinh OpenStreetMap nhúng có bo góc và viền nổi bật
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                OsmMapWidget(
                  centerLatitude: widget.latitude,
                  centerLongitude: widget.longitude,
                  places: places,
                  selectedPlace: _selectedPlace,
                  mapController: _mapController,
                  onPlaceSelected: (place) => _onPlaceTap(place, moveMap: false),
                ),

                // Floating pill: gợi ý tương tác bản đồ
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          _selectedPlace != null ? 'Đang chọn: ${_selectedPlace!.name}' : 'Chạm ghim để xem vị trí',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating button: Định vị lại tâm bản đồ vào vị trí người dùng
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        _mapController.move(LatLng(widget.latitude, widget.longitude), 14.5);
                        setState(() {
                          _selectedPlace = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.my_location_rounded, size: 20, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Thanh tóm tắt thông tin kết quả (Đồng bộ style với các Banner của RecommendationResultScreen)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🛵', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'TÌM THẤY ${places.length} QUÁN GẦN',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppTheme.onPrimaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.radar, size: 13, color: AppTheme.secondary),
                    SizedBox(width: 4),
                    Text(
                      'Bán kính: ~3 km',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Danh sách thẻ các quán ăn
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            itemCount: places.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final place = places[index];
              final isSelected = _selectedPlace?.name == place.name;
              final isNearest = index == 0;

              return InkWell(
                onTap: () => _onPlaceTap(place, moveMap: true),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryFixed.withValues(alpha: 0.16)
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineVariant.withValues(alpha: 0.4),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0x22FF6B35)
                            : const Color(0x0A000000),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header quán: Thứ tự, tên quán, khoảng cách
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge số thứ tự (Quán gần nhất #1 có màu nổi bật)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isNearest
                                  ? AppTheme.primary
                                  : AppTheme.surfaceContainerHigh,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isNearest ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Tên quán
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (isNearest) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tertiaryFixed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '⭐ Gần bạn nhất',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onTertiaryFixedVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Khoảng cách
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded, size: 12, color: AppTheme.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDistance(place.distance),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Địa chỉ quán
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.address,
                              style: const TextStyle(
                                fontSize: 12.8,
                                color: AppTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Tag thông tin phụ: Thời gian di chuyển & đánh giá
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.moped_rounded, size: 13, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  _estimateDriveTime(place.distance),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (place.rating > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryFixed.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppTheme.tertiaryAmber),
                                  const SizedBox(width: 3),
                                  Text(
                                    place.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onTertiaryFixed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryFixed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '📍 Đang xem ghim',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onPrimaryFixed,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.surfaceContainer),
                      const SizedBox(height: 10),

                      // Action bar: Sao chép địa chỉ & Nút Chỉ đường
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _copyAddress(place.address),
                            icon: const Icon(Icons.copy_rounded, size: 15, color: AppTheme.textSecondary),
                            label: const Text(
                              'Sao chép',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                            onPressed: () {
                              if (place.mapUrl.isNotEmpty) {
                                DeeplinkService.openUrl(place.mapUrl);
                              } else {
                                DeeplinkService.openMapDirections(
                                  place.latitude,
                                  place.longitude,
                                );
                              }
                            },
                            icon: const Icon(Icons.directions_rounded, size: 17),
                            label: const Text(
                              'Chỉ đường',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
