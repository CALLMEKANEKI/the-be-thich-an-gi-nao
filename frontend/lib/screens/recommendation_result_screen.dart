import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/wheel_option.dart';
import '../provider/places_provider.dart';
import '../provider/recommendation_provider.dart';
import 'ingredients_screen.dart';
import 'restaurant_result_screen.dart';

/// Screen 04_Recommendation_Result, 04_Recommendation_Loading, 04_Recommendation_Error
/// from Stitch Project "Food Decider Flutter UI"
class RecommendationResultScreen extends StatefulWidget {
  final WheelOption? option;
  final double latitude;
  final double longitude;

  const RecommendationResultScreen({
    super.key,
    this.option,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<RecommendationResultScreen> createState() =>
      _RecommendationResultScreenState();
}

class _RecommendationResultScreenState extends State<RecommendationResultScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<RecommendationProvider>(
      builder: (context, provider, _) {
        final option = widget.option ?? provider.selectedOption;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Kết quả gợi ý'),
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
          body: SafeArea(
            child: switch (provider.status) {
              RecommendationStatus.loading => _buildLoadingState(),
              RecommendationStatus.error => _buildErrorState(provider),
              _ => option == null
                  ? _buildEmptyOrLoadingState()
                  : _buildSuccessState(option),
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // 1. SUCCESS STATE (04_Recommendation_Result)
  // ==========================================
  Widget _buildSuccessState(WheelOption option) {
    final dish = option.dish;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner: Personalized by AI
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('🎉', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'MÓN NGON CHUẨN VỊ CHO BẠN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
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
                    Icon(Icons.verified, size: 14, color: AppTheme.secondary),
                    SizedBox(width: 4),
                    Text(
                      'Được AI cá nhân hóa',
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

          const SizedBox(height: 14),

          // Hero Food Card with Image & Details
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12FF6B35),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    // Dish Image Banner
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB59D), Color(0xFFFF6B35)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        image: dish.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(dish.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: dish.imageUrl.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.ramen_dining,
                                size: 80,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),

                    // Dark gradient overlay
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0xB3000000)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Top right action buttons: Favorite & Share
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        children: [
                          _buildGlassIconButton(
                            icon: _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : AppTheme.primary,
                            onTap: () => setState(() => _isFavorite = !_isFavorite),
                          ),
                          const SizedBox(width: 8),
                          _buildGlassIconButton(
                            icon: Icons.share,
                            color: AppTheme.onSurfaceVariant,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã sao chép link chia sẻ món ${dish.name}!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Bottom title tag
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.auto_awesome,
                                    size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'LỰA CHỌN SỐ 1 HÔM NAY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dish.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dish metadata pills
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetaPill('🍜', 'Món nước ấm nóng'),
                      _buildMetaPill('⏱️', '35 phút'),
                      _buildMetaPill('🔥', '540 kcal'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lý do gợi ý Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryFixed.withValues(alpha: 0.4),
                  AppTheme.surfaceContainerLow,
                  AppTheme.tertiaryFixed.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.psychology,
                                size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Lý do gợi ý',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          const Text(
                            'Độ tin cậy: ',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                          Text(
                            '${(option.confidence * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  option.reason.isNotEmpty
                      ? option.reason
                      : 'Gợi ý dựa trên tâm trạng vui vẻ, thời tiết dịu mát và khẩu vị ấm nồng thơm ngon.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                // 3 Criteria mini tiles
                Row(
                  children: [
                    _buildReasonTile('😊', 'Tâm trạng', 'Hào hứng'),
                    const SizedBox(width: 8),
                    _buildReasonTile('🌦️', 'Thời tiết', '28°C Nắng nhẹ'),
                    const SizedBox(width: 8),
                    _buildReasonTile('🍲', 'Khẩu vị', 'Đậm đà cay ấm'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Ingredients Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text(
                        'Nguyên liệu chuẩn bị nhanh',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '5 món chính',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildIngredientChip('🥢', 'Bún tươi sợi to'),
                    _buildIngredientChip('🥩', 'Bắp bò & nạm'),
                    _buildIngredientChip('🦀', 'Chả cua Huế'),
                    _buildIngredientChip('🥗', 'Rau chuối & húng quế'),
                    _buildIngredientChip('🌶️', 'Sả & ớt sa tế'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Two Main CTA Buttons (Eat Out & Cook at Home)
          Column(
            children: [
              // CTA 1: ĂN QUÁN NGAY
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Prefetch and navigate to Restaurant Screen
                    context.read<PlacesProvider>().prefetch(
                          dishName: dish.name,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantResultScreen(
                          dishName: dish.name,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0x4DFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'ĂN QUÁN NGAY',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Tìm quán ngon gần đây nhất',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryFixed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CTA 2: TỰ NẤU TẠI NHÀ
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IngredientsScreen(
                          dishId: dish.id,
                          dishName: dish.name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryFixed.withValues(alpha: 0.6),
                    foregroundColor: AppTheme.onPrimaryFixed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.soup_kitchen, size: 24, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'TỰ NẤU TẠI NHÀ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onPrimaryFixed,
                              ),
                            ),
                            Text(
                              'Xem nguyên liệu & công thức 4 bước',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 20, color: AppTheme.onPrimaryFixed),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reshuffle button
          Center(
            child: InkWell(
              onTap: () {
                final newIndex = context.read<RecommendationProvider>().pickRandomIndex();
                context.read<RecommendationProvider>().selectDishByIndex(newIndex);
              },
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.casino, size: 18, color: AppTheme.onSurfaceVariant),
                    SizedBox(width: 6),
                    Text(
                      'Chưa ưng ý? Gợi ý món khác',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==========================================
  // 2. LOADING STATE (04_Recommendation_Loading)
  // ==========================================
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Animated Radar/Pulsing Food Mascot
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryFixed.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      backgroundColor: AppTheme.primaryFixed,
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryContainer,
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
          ),

          const SizedBox(height: 20),

          const Text(
            'Đang phân tích món ngon phù hợp...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đang tổng hợp dữ liệu tâm trạng, thời tiết 28°C và khẩu vị yêu thích của bé...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          // Progress Checklist Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text(
                        'Tiến trình AI gợi ý',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '68%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.68,
                    backgroundColor: AppTheme.surfaceContainer,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                _buildChecklistRow(
                  title: 'Phân tích tâm trạng',
                  status: 'Hoàn tất 100%',
                  isDone: true,
                  icon: Icons.check,
                ),
                const SizedBox(height: 10),
                _buildChecklistRow(
                  title: 'Quét xu hướng & nhiệt độ 28°C',
                  status: 'Đang tính toán...',
                  isLoading: true,
                  icon: Icons.sync,
                ),
                const SizedBox(height: 10),
                _buildChecklistRow(
                  title: 'Chọn lọc nguyên liệu & quán ngon',
                  status: 'Sắp xong...',
                  isPending: true,
                  icon: Icons.pending,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tip banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.celebration, color: AppTheme.tertiaryAmber, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chờ chút xíu nhé, món ngon bất ngờ sắp xuất hiện rồi nè! 🍜✨',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
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
  // 3. ERROR STATE (04_Recommendation_Error)
  // ==========================================
  Widget _buildErrorState(RecommendationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Interrupt badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryFixed,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.wifi_off, size: 16, color: AppTheme.onPrimaryFixedVariant),
                SizedBox(width: 6),
                Text(
                  'Đang gián đoạn kết nối',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onPrimaryFixedVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Empty Bowl Illustration Card
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
                // Cute soup bowl visual
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🥣', style: TextStyle(fontSize: 48)),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Chưa tìm thấy món phù hợp rồi!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hệ thống chưa thể gợi ý món ăn vào lúc này do kết nối mạng chập chờn. Bé hãy thử lại một lần nữa nhé!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Button 1: THỬ LẠI NGAY
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.fetchWheelOption(
                        'Hôm nay bé muốn ăn gì',
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
                        Icon(Icons.sync, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'THỬ LẠI NGAY',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Button 2: QUAY LẠI CHỌN TÂM TRẠNG
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryFixed.withValues(alpha: 0.5),
                      foregroundColor: AppTheme.onPrimaryFixed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.sentiment_satisfied, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'QUAY LẠI CHỌN TÂM TRẠNG',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb, color: AppTheme.secondaryMint, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mẹo nhỏ: Kiểm tra lại Wi-Fi hoặc 4G/5G để đón thực đơn thơm ngon nhé.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildMetaPill(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow({
    required String title,
    required String status,
    required IconData icon,
    bool isDone = false,
    bool isLoading = false,
    bool isPending = false,
  }) {
    Color bg = AppTheme.surfaceContainerLow;
    Color fg = AppTheme.onSurface;
    Color statusColor = AppTheme.secondary;

    if (isLoading) {
      bg = AppTheme.primaryFixed.withValues(alpha: 0.3);
      statusColor = AppTheme.primary;
    } else if (isPending) {
      bg = AppTheme.surfaceContainerLowest;
      fg = AppTheme.onSurfaceVariant;
      statusColor = AppTheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppTheme.secondaryContainer
                  : (isLoading ? AppTheme.primaryContainer : AppTheme.surfaceContainer),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDone
                  ? AppTheme.onSecondaryContainer
                  : (isLoading ? Colors.white : AppTheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
