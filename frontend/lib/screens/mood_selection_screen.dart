import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../provider/recommendation_provider.dart';
import '../services/location_service.dart';
import 'spin_wheel_screen.dart';

/// Screen 02_Mood_Selection from Stitch Project "Food Decider Flutter UI"
class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  final TextEditingController _customMoodController = TextEditingController();

  int _selectedMoodIndex = 0;
  double? _latitude = LocationService.defaultLatitude;
  double? _longitude = LocationService.defaultLongitude;
  bool _isLoadingGps = false;
  String _weatherText = '28°C Nắng nhẹ • Vị trí hiện tại';

  final List<Map<String, dynamic>> _moodList = [
    {
      'id': 'happy',
      'title': 'Vui vẻ & Hứng khởi',
      'emoji': '😊',
      'description':
          'Tâm trạng phấn chấn, muốn ăn gì đó thật ngon miệng, rực rỡ và tươi tắn!',
      'icon': Icons.sentiment_very_satisfied,
    },
    {
      'id': 'comfort',
      'title': 'Cần dỗ dành',
      'emoji': '😢',
      'description':
          'Cần món ấm nóng dịu ngọt, comfort food xoa dịu tâm hồn và dạ dày.',
      'icon': Icons.soup_kitchen,
    },
    {
      'id': 'tired',
      'title': 'Mệt mỏi & Uể oải',
      'emoji': '😴',
      'description':
          'Cần nạp năng lượng nhanh, món thanh đạm, giàu vitamin và dễ tiêu hóa.',
      'icon': Icons.bedtime,
    },
    {
      'id': 'craving',
      'title': 'Đói cồn cào',
      'emoji': '🤤',
      'description':
          'Muốn món đậm đà, giòn rụm với topping đầy ắp, ăn no căng bụng!',
      'icon': Icons.local_fire_department,
    },
    {
      'id': 'chill',
      'title': 'Chill & Thư thái',
      'emoji': '🌿',
      'description':
          'Món nhẹ nhàng, thanh lọc cơ thể, nhâm nhi cùng nước mát.',
      'icon': Icons.eco,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchGps();
  }

  @override
  void dispose() {
    _customMoodController.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    setState(() => _isLoadingGps = true);
    final Position? pos = await LocationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _isLoadingGps = false;
        if (pos != null) {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _weatherText =
              '28°C Nắng nhẹ • GPS (${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)})';
        } else {
          _weatherText = '28°C Nắng nhẹ • Quận 1, TP.HCM';
        }
      });
    }
  }

  void _onContinue() {
    final selectedMood = _moodList[_selectedMoodIndex];
    final customText = _customMoodController.text.trim();
    final queryText = customText.isNotEmpty
        ? '$customText (${selectedMood['title']})'
        : selectedMood['title'] as String;

    // Gọi API lấy 10 món gợi ý
    final provider = context.read<RecommendationProvider>();
    provider.fetchWheelOption(
      queryText,
      latitude: _latitude,
      longitude: _longitude,
    );

    // Chuyển sang màn hình Vòng quay may mắn
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpinWheelScreen(
          latitude: _latitude ?? LocationService.defaultLatitude,
          longitude: _longitude ?? LocationService.defaultLongitude,
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
        title: const Text('Chọn tâm trạng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hệ thống AI sẽ dựa vào tâm trạng để gợi ý món ăn tối ưu.'),
                ),
              );
            },
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper Indicator (Bước 1 trên 3 - 33%)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'BƯỚC 1 TRÊN 3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '33%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: AppTheme.surfaceContainer,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryContainer),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.favorite, size: 16, color: AppTheme.primary),
                  SizedBox(width: 4),
                  Text(
                    'Cảm xúc hôm nay',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Prompt Headline & Context
              const Text(
                'Hôm nay bé đang cảm thấy thế nào?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn 1 tâm trạng để gợi ý món ăn chuẩn vị và tràn đầy năng lượng nhé!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Weather & Sensor Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.tertiaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wb_sunny,
                        color: AppTheme.onTertiaryFixed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GỢI Ý THỜI TIẾT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _weatherText,
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
                    if (_isLoadingGps)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tự động',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mood Cards Collection
              ListView.separated(
                itemCount: _moodList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _moodList[index];
                  final isSelected = index == _selectedMoodIndex;

                  return InkWell(
                    onTap: () => setState(() => _selectedMoodIndex = index),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryFixed
                            : AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0x20FF6B35)
                                : const Color(0x08000000),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Emoji Avatar
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.6)
                                  : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item['emoji'] as String,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.onPrimaryFixed
                                        : AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item['description'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? AppTheme.onPrimaryFixedVariant
                                        : AppTheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Radio indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Optional Custom Mood Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _customMoodController,
                        decoration: const InputDecoration(
                          hintText: 'Hoặc tự nhập tâm trạng, thèm món gì...',
                          hintStyle: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Bottom CTA
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onContinue,
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
                        'TIẾP TỤC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
