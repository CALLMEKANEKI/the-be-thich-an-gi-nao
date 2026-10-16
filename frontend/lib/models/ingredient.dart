class Ingredient {
  final String name;
  final String normalizedName;
  final double quantity;
  final String unit;

  Ingredient({
    required this.name,
    required this.normalizedName,
    required this.quantity,
    required this.unit,
  });

  // Đọc từ GET /api/v1/dishes/{id}/ingredients (field gốc tên "ingredient")
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['ingredient'],
      normalizedName: json['normalized_name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
    );
  }

  // Gửi lên POST /api/v1/cart (field tên "name")
  Map<String, dynamic> toCartJson() => {
        'name': name,
        'normalized_name': normalizedName,
        'quantity': quantity,
        'unit': unit,
      };
}