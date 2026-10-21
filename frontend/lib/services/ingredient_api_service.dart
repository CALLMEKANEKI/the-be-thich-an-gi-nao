import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/ingredient.dart';

class IngredientApiService {
  Future<List<Ingredient>> getIngredients(int dishId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/dishes/$dishId/ingredients');
    final response = await http.get(url).timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      final List<dynamic> rawList = jsonMap['data']['items'] ?? [];
      return rawList
          .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy thông tin món ăn');
    } else if (response.statusCode == 503) {
      throw Exception('AI đang bận tạo nguyên liệu, vui lòng thử lại sau giây lát');
    } else {
      throw Exception('Lỗi máy chủ (${response.statusCode})');
    }
  }
}
