import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wheel_option.dart';

class LuckyWheelPainter extends CustomPainter {
  final List<WheelOption> items;
  final double currentRotation; // Angle in radians

  static const List<Color> _sliceColors = [
    Color(0xFFFF7043), // Deep Orange
    Color(0xFFFFB74D), // Amber Orange
    Color(0xFFFFD54F), // Light Amber
    Color(0xFF81C784), // Soft Green
    Color(0xFF4DB6AC), // Teal
    Color(0xFF4FC3F7), // Light Blue
    Color(0xFF7986CB), // Indigo
    Color(0xFFBA68C8), // Purple
    Color(0xFFFF8A80), // Soft Coral
    Color(0xFFA1887F), // Warm Brown
  ];

  LuckyWheelPainter({
    required this.items,
    required this.currentRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final sliceAngle = 2 * pi / items.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final outerRingPaint = Paint()
      ..color = const Color(0xFFE64A19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // Lưu trạng thái trước khi xoay toàn bộ vòng quay
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(currentRotation);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < items.length; i++) {
      paint.color = _sliceColors[i % _sliceColors.length];
      final startAngle = i * sliceAngle;

      // Vẽ lát bánh
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // Vẽ viền trắng chia các lát
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      // Vẽ chữ tên món
      _drawText(
        canvas,
        center,
        radius,
        startAngle + sliceAngle / 2,
        items[i].dish.name,
      );
    }

    // Vẽ vành ngoài
    canvas.drawCircle(center, radius, outerRingPaint);

    // Vẽ các chấm trang trí viền
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (int i = 0; i < items.length * 2; i++) {
      final angle = i * (pi / items.length);
      final dotOffset = Offset(
        center.dx + (radius + 1) * cos(angle),
        center.dy + (radius + 1) * sin(angle),
      );
      canvas.drawCircle(dotOffset, 2.5, dotPaint);
    }

    canvas.restore();

    // Vẽ tâm vòng xoay (trục giữa)
    final hubBorder = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final hubCore = Paint()..color = const Color(0xFFD84315)..style = PaintingStyle.fill;

    canvas.drawCircle(center, 22, hubBorder);
    canvas.drawCircle(center, 16, hubCore);
  }

  void _drawText(Canvas canvas, Offset center, double radius, double angle, String text) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final textSpan = TextSpan(
      text: text.length > 14 ? '${text.substring(0, 12)}…' : text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black45),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: radius * 0.65);

    // Đặt chữ dọc theo lát xoay từ tâm ra rìa
    canvas.translate(radius * 0.38, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LuckyWheelPainter oldDelegate) {
    return oldDelegate.currentRotation != currentRotation ||
        oldDelegate.items != items;
  }
}
