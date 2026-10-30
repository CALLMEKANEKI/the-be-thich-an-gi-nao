import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/wheel_option.dart';
import '../provider/places_provider.dart';
import '../provider/recommendation_provider.dart';
import '../widgets/lucky_wheel_painter.dart';
import 'ingredients_screen.dart';
import 'restaurant_result_screen.dart';

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
        _showResultSheet();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Bắt đầu quay vòng may mắn theo đúng chuẩn Handoff Guide:
  /// 1. Random trước 1 index trên Flutter (0..total-1)
  /// 2. Bắt đầu prefetch quán bằng unawaited() ngầm
  /// 3. Animation quay mượt mà không chờ API
  void _startSpin(List<WheelOption> options) {
    if (_isSpinning || options.isEmpty) return;

    final targetIndex = Random().nextInt(options.length);
    final winningOption = options[targetIndex];

    // Cập nhật món được chọn vào provider
    context.read<RecommendationProvider>().selectDishByIndex(targetIndex);

    // BẮT BUỘC (Handoff Guide): Gọi prefetch ngầm bằng unawaited(), animation không chờ request
    unawaited(
      context.read<PlacesProvider>().prefetch(
            dishName: winningOption.dish.name,
            latitude: widget.latitude,
            longitude: widget.longitude,
          ),
    );

    // Tính góc quay:
    // Kim chỉ nằm ở đỉnh (góc 3*pi / 2 hoặc 270 độ, tức -pi/2).
    // Mỗi lát có góc sliceAngle = 2*pi / length.
    // Tâm lát thứ i nằm ở: i * sliceAngle + sliceAngle / 2.
    final sliceAngle = 2 * pi / options.length;
    final targetCenterAngle = targetIndex * sliceAngle + sliceAngle / 2;

    // Để kim (ở đỉnh -pi/2) trỏ đúng tâm lát:
    // currentRotation + targetCenterAngle = -pi/2 + K * 2*pi
    final fullSpins = 5 + Random().nextInt(3); // quay 5 đến 7 vòng
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

  /// Hiển thị kết quả món ăn trúng thưởng (Task 7: Recommendation Result UI)
  void _showResultSheet() {
    final provider = context.read<RecommendationProvider>();
    final option = provider.selectedOption;
    if (option == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildResultModal(ctx, option),
    );
  }

  Widget _buildResultModal(BuildContext ctx, WheelOption option) {
    final dish = option.dish;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Huy hiệu chúc mừng
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Món Ăn Dành Cho Bạn!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tên món & phân loại
          Text(
            dish.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (dish.category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dish.category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Lý do gợi ý & Độ tự tin
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.reason,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.brown.shade800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Độ phù hợp: ${(option.confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hai nút hành động: "Ra ngoài ăn" và "Tự nấu"
          Row(
            children: [
              // Nút 1: Ra ngoài ăn
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5), // Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
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
                  icon: const Icon(Icons.storefront, size: 20),
                  label: const Text(
                    'Ra ngoài ăn 🛵',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nút 2: Tự nấu
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
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
                  icon: const Icon(Icons.kitchen, size: 20),
                  label: const Text(
                    'Tự nấu 🍳',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vòng Quay May Mắn 🎯'),
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            RecommendationStatus.idle => const Center(
                child: Text('Chưa có danh sách món ăn để quay.'),
              ),
            RecommendationStatus.loading => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'AI đang chọn lọc 10 món ngon theo cảm xúc...',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            RecommendationStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage ?? 'Đã có lỗi xảy ra',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            RecommendationStatus.success => _buildWheelUI(provider.wheelOptions),
          };
        },
      ),
    );
  }

  Widget _buildWheelUI(List<WheelOption> options) {
    if (options.isEmpty) {
      return const Center(child: Text('Không có món ăn nào trong danh sách.'));
    }

    final size = MediaQuery.of(context).size.width * 0.88;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Hướng dẫn
          Text(
            _isSpinning ? 'Đang quay... Chờ món trúng thưởng nào!' : 'Bấm nút giữa hoặc nút Quay để chọn món!',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Vòng quay + Kim chỉ
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng xoay Canvas
                  CustomPaint(
                    size: Size(size, size),
                    painter: LuckyWheelPainter(
                      items: options,
                      currentRotation: _currentRotation,
                    ),
                  ),

                  // Nút bấm tâm vòng quay
                  GestureDetector(
                    onTap: _isSpinning ? null : () => _startSpin(options),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _isSpinning ? Colors.grey : AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Center(
                        child: Text(
                          'SPIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kim chỉ góc trên (Indicator Arrow pointing down)
                  Positioned(
                    top: 0,
                    child: Column(
                      children: [
                        CustomPaint(
                          size: const Size(26, 26),
                          painter: _TrianglePointerPainter(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Nút bấm Quay lớn bên dưới
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSpinning ? null : () => _startSpin(options),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                _isSpinning ? 'Đang chọn món...' : 'QUAY NGAY 🎯',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD50000)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
