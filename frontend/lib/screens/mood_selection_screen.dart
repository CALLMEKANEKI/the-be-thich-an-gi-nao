import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../provider/recommendation_provider.dart';
import '../services/location_service.dart';
import 'spin_wheel_screen.dart';

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  final TextEditingController _textController = TextEditingController(
    text: 'Hôm nay mệt quá, chán ăn ghê',
  );

  double? _latitude = LocationService.defaultLatitude;
  double? _longitude = LocationService.defaultLongitude;
  bool _isLoadingGps = false;
  String _gpsNote = 'Quận 1, TP. Hồ Chí Minh (mặc định)';

  final List<Map<String, String>> _quickMoods = [
    {'emoji': '😴', 'text': 'Hôm nay mệt mỏi, muốn ăn gì đó nhẹ bụng'},
    {'emoji': '🌧️', 'text': 'Trời mưa lành lạnh, thèm món nước nóng hổi'},
    {'emoji': '🥳', 'text': 'Tâm trạng vui vẻ, muốn ăn món gì thịnh soạn'},
    {'emoji': '🌶️', 'text': 'Thèm đồ cay nồng, đậm đà kích thích vị giác'},
    {'emoji': '🥗', 'text': 'Muốn ăn đồ healthy, thanh đạm và nhiều rau'},
    {'emoji': '🍖', 'text': 'Đang rất đói, cần món nhiều đạm no lâu'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchGps();
  }

  @override
  void dispose() {
    _textController.dispose();
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
          _gpsNote = 'GPS hiện tại: (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)})';
        } else {
          _gpsNote = 'Dùng toạ độ mặc định (Quận 1, TP.HCM)';
        }
      });
    }
  }

  void _onSpinPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tâm trạng hoặc chọn gợi ý bên dưới!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Gọi API lấy 10 món gợi ý
    final provider = context.read<RecommendationProvider>();
    provider.fetchWheelOption(
      text,
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
      appBar: AppBar(
        title: const Text('Thế bé thích ăn gì nào? 💕'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Subtitle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.12),
                    AppTheme.secondaryColor.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Text('🍳', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hôm nay bạn cảm thấy thế nào?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'AI sẽ đọc cảm xúc & thời tiết để gợi ý thực đơn chuẩn gu cho bạn!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ô nhập cảm xúc
            const Text(
              'Tâm trạng / Cảm xúc hiện tại:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 3,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Nhập cảm xúc của bạn... (Ví dụ: Mệt mỏi, thèm đồ ngọt, đói cồn cào...)',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.cardBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gợi ý tâm trạng nhanh (Quick tags)
            const Text(
              'Hoặc chọn nhanh:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickMoods.map((mood) {
                return ActionChip(
                  avatar: Text(mood['emoji']!, style: const TextStyle(fontSize: 14)),
                  label: Text(
                    mood['text']!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.cardBorderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    setState(() {
                      _textController.text = mood['text']!;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Định vị GPS
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    if (_isLoadingGps)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _gpsNote,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: AppTheme.textSecondary),
                      tooltip: 'Cập nhật lại GPS',
                      onPressed: _isLoadingGps ? null : _fetchGps,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Nút bấm chính
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _onSpinPressed,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  'Gợi Ý Món Ăn & Vòng Quay 🎯',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
