class DishRecommendation {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;

  DishRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
  });

  factory DishRecommendation.fromJson(Map<String, dynamic> json) {
    return DishRecommendation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      category: json['category'] as String? ?? 'Khác',
    );
  }
}