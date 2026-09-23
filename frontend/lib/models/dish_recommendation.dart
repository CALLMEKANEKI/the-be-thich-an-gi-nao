class DishRecommendation {
  final String name;
  final String description;
  final String reason;
  final double confidence;

  DishRecommendation({
    required this.name,
    required this.description,
    required this.reason,
    required this.confidence,
  });

  factory DishRecommendation.fromJson(Map<String, dynamic> json){
    final data = json['data'];
    final dish = data['dish'];

    return DishRecommendation(
      name: dish['name'], 
      description: dish['description'], 
      reason: data['reason'], 
      confidence: (data['confidence'] as num).toDouble(),
    );   
  }
}