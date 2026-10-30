import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/location_service.dart';
import 'map_poc_screen.dart';
import 'mood_selection_screen.dart';
import 'spin_wheel_screen.dart';

/// Screen 01_Home from Stitch Project "Food Decider Flutter UI"
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // 1. Friendly Greeting Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Chào bé yêu! 👋',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onPrimaryFixed,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. App Identity
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.ramen_dining,
                      color: AppTheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'THẾ BÉ THÍCH ĂN GÌ?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. Main Headline
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                    height: 1.2,
                    fontFamilyFallback: ['Roboto', 'sans-serif'],
                  ),
                  children: [
                    TextSpan(text: 'Hôm nay bé\n'),
                    TextSpan(
                      text: 'muốn ăn gì?',
                      style: TextStyle(color: AppTheme.primaryContainer),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 4. Descriptive Microcopy
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: const Text(
                  'Ứng dụng thông minh gợi ý món ngon chuẩn vị dựa trên tâm trạng, thời tiết và sở thích của bạn chỉ với 1 chạm!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Hero Illustration Visual Card
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Floating tags
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFloatingTag(
                          icon: Icons.local_pizza,
                          label: 'Giòn rụm',
                          bg: AppTheme.tertiaryFixed,
                          fg: AppTheme.onTertiaryFixed,
                        ),
                        _buildFloatingTag(
                          icon: Icons.soup_kitchen,
                          label: 'Nóng hổi',
                          bg: AppTheme.secondaryContainer,
                          fg: AppTheme.onSecondaryContainer,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Food image preview / banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Container(
                            height: 170,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFB59D), Color(0xFFFF6B35)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            height: 60,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Color(0x80000000)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: const [
                                Icon(Icons.star, color: Color(0xFFFFD54F), size: 18),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Đa dạng món ngon cho bé thỏa sức chọn',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Nutrition Mini Pill Meter
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.recommend, color: AppTheme.primary, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Gợi ý thông minh:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: const [
                              Icon(Icons.restaurant, color: AppTheme.primary, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Chuẩn vị & ngon miệng',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. Feature Discovery Pills Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'TÍNH NĂNG NỔI BẬT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
                ],
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _buildFeaturePill(
                    context: context,
                    icon: Icons.bolt,
                    title: 'Theo tâm trạng',
                    subtitle: 'Vui, đói, chill',
                    iconBg: AppTheme.primaryFixed,
                    iconFg: AppTheme.onPrimaryFixed,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodSelectionScreen()),
                    ),
                  ),
                  _buildFeaturePill(
                    context: context,
                    icon: Icons.casino,
                    title: 'Vòng quay vui',
                    subtitle: 'Chọn ngẫu nhiên',
                    iconBg: AppTheme.tertiaryFixed,
                    iconFg: AppTheme.onTertiaryFixed,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpinWheelScreen(
                          latitude: LocationService.defaultLatitude,
                          longitude: LocationService.defaultLongitude,
                        ),
                      ),
                    ),
                  ),
                  _buildFeaturePill(
                    context: context,
                    icon: Icons.near_me,
                    title: 'Quán ngon gần',
                    subtitle: 'Xem trên bản đồ',
                    iconBg: AppTheme.secondaryContainer,
                    iconFg: AppTheme.onSecondaryContainer,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapPocScreen()),
                    ),
                  ),
                  _buildFeaturePill(
                    context: context,
                    icon: Icons.soup_kitchen,
                    title: 'Tìm món để nấu',
                    subtitle: 'Chọn món gợi ý trước',
                    iconBg: AppTheme.primaryFixedDim,
                    iconFg: AppTheme.onPrimaryFixedVariant,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MoodSelectionScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 7. Bottom CTA Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodSelectionScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: AppTheme.onPrimary,
                    elevation: 4,
                    shadowColor: const Color(0x4DFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'BẮT ĐẦU',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.rocket_launch, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Delight Helper Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.timer_outlined, size: 16, color: AppTheme.primary),
                  SizedBox(width: 4),
                  Text(
                    'Khám phá món ngon trong 30 giây',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingTag({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconFg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconFg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
    );
  }
}
