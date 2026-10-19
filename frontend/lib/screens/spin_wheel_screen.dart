import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/wheel_option.dart';
import '../provider/places_provider.dart';
import '../provider/recommendation_provider.dart';
import '../widgets/lucky_wheel_painter.dart';
import 'recommendation_result_screen.dart';

/// Screen 03_Spin_Wheel & 03_Spin_Wheel_Loading from Stitch Project "Food Decider Flutter UI"
class SpinWheelScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const SpinWheelScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentRotation = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addListener(() {
      setState(() {
        _currentRotation = _animation.value;
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        _navigateToResult();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Bắt đầu quay vòng may mắn theo Handoff Guide:
  /// 1. Random trước 1 index (0..total-1)
  /// 2. Bắt đầu prefetch quán ngầm bằng unawaited()
  /// 3. Animation quay mượt mà không chờ API
  void _startSpin(List<WheelOption> options) {
    if (_isSpinning || options.isEmpty) return;

    final targetIndex = Random().nextInt(options.length);
    final winningOption = options[targetIndex];

    context.read<RecommendationProvider>().selectDishByIndex(targetIndex);

    // Prefetch ngầm bằng unawaited()
    unawaited(
      context.read<PlacesProvider>().prefetch(
            dishName: winningOption.dish.name,
            latitude: widget.latitude,
            longitude: widget.longitude,
          ),
    );

    final sliceAngle = 2 * pi / options.length;
    final targetCenterAngle = targetIndex * sliceAngle + sliceAngle / 2;
    final fullSpins = 5 + Random().nextInt(3);
    final double targetAngle = (fullSpins * 2 * pi) + (3 * pi / 2 - targetCenterAngle);

    _controller.reset();
    _animation = Tween<double>(
      begin: _currentRotation % (2 * pi),
      end: _currentRotation + targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    setState(() {
      _isSpinning = true;
    });

    _controller.forward();
  }

  void _navigateToResult() {
    final provider = context.read<RecommendationProvider>();
    final option = provider.selectedOption;
    if (option == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationResultScreen(
          option: option,
          latitude: widget.latitude,
          longitude: widget.longitude,
        ),
      ),
    );
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
        title: const Text('Vòng quay may mắn'),
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
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            RecommendationStatus.loading => _buildSpinWheelLoading(),
            RecommendationStatus.error => _buildErrorState(provider),
            _ => _buildWheelUI(provider.wheelOptions),
          };
        },
      ),
    );
  }

  // ==========================================
  // 1. LOADING STATE (03_Spin_Wheel_Loading)
  // ==========================================
  Widget _buildSpinWheelLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Orbiting Animation Visual
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.outlineVariant.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryFixedDim,
                        width: 2,
                      ),
                    ),
                  ),
                  // Rotating Core
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang trộn vị ngon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onPrimaryFixed,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Đang quay tìm món ngon cho bé...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: const Text(
                'Vũ trụ ẩm thực đang kết nối sở thích, tâm trạng và thời tiết hôm nay để chọn món chuẩn vị nhất!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Step Progress Card
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
                      Text(
                        'TIẾN TRÌNH ĐỀ XUẤT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Bước 2 / 3',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.66,
                      backgroundColor: AppTheme.surfaceContainer,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cancel Button
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Dừng quay và quay lại'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.onSurfaceVariant,
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
  Widget _buildErrorState(RecommendationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Không thể tải món quay',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại chọn tâm trạng'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. SUCCESS / ACTIVE WHEEL (03_Spin_Wheel)
  // ==========================================
  Widget _buildWheelUI(List<WheelOption> options) {
    if (options.isEmpty) {
      return const Center(child: Text('Không có món ăn nào trong danh sách.'));
    }

    final size = MediaQuery.of(context).size.width * 0.85;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Headline & Subtitle
            const Text(
              'Quay để tìm món nhé!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chạm vào nút QUAY hoặc chạm vào tâm vòng quay',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            // Wheel Container with Canvas and Center Pin
            Center(
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Canvas Wheel
                    CustomPaint(
                      size: Size(size, size),
                      painter: LuckyWheelPainter(
                        items: options,
                        currentRotation: _currentRotation,
                      ),
                    ),

                    // Center Button
                    GestureDetector(
                      onTap: _isSpinning ? null : () => _startSpin(options),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isSpinning
                              ? Colors.grey.shade400
                              : AppTheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33FF6B35),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ),

                    // Pointer Top Arrow
                    Positioned(
                      top: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryDark,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x30000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Action Button 1: QUAY NGAY
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSpinning ? null : () => _startSpin(options),
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
                  children: [
                    Icon(
                      _isSpinning ? Icons.hourglass_top : Icons.play_circle,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isSpinning ? 'ĐANG QUAY...' : 'QUAY NGAY',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action Button 2: Tùy chỉnh danh sách món
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showCustomizationDialog(options);
                },
                icon: const Icon(Icons.tune, size: 18, color: AppTheme.onSurfaceVariant),
                label: const Text(
                  'Tùy chỉnh danh sách món',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCustomizationDialog(List<WheelOption> options) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Món ăn trên vòng (${options.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.restaurant, color: AppTheme.primary, size: 18),
                    title: Text(
                      options[i].dish.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      options[i].dish.category,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
