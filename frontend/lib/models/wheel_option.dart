import 'package:frontend/models/dish_recommendation.dart';

class WheelOption {
  final DishRecommendation dish;
  final String reason;
  final double confidence;

  WheelOption({
    required this.dish,
    required this.reason,
    required this.confidence,
  });

  factory WheelOption.fromJson(Map<String, dynamic> json) {
    final dishJson = json['dish'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return WheelOption(
      dish: DishRecommendation.fromJson(dishJson),
      reason: json['reason'] ?? '',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
    );
  }
}