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

  factory WheelOption.fromJson(Map<String, dynamic> json){
    return WheelOption(
      dish: DishRecommendation.fromJson(json['dish']),
      reason: json['reason'],
      confidence: (json['confidence'] as num).toDouble(), 
    );
  }
}