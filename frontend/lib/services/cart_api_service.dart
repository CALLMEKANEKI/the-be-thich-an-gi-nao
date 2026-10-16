import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_result.dart';
import '../models/ingredient.dart';
import 'local_cache_service.dart';

class CartApiService {
  final String _baseUrl = 'http://10.0.2.2:8000';
  static const String _cacheKey = 'cart_last';
  final LocalCacheService _cache = LocalCacheService();

  Future<CartResult> createCart({
    required int dishId,
    required String dishName,
    required List<Ingredient> ingredients,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/cart'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'dish': {'id': dishId, 'name': dishName},
        'ingredients': ingredients.map((i) => i.toCartJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi server: ${response.statusCode}');
    }

    // Parse trước. Parse thành công mới lưu cache, nên không bao giờ lưu dữ liệu hỏng.
    final result =
        CartResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);


    try {
      await _cache.saveCache(_cacheKey, response.body);  // lưu CHUỖI GỐC của server
    } catch (_) {
      // lỗi cache không được làm hỏng luồng chính
    }
    return result;
  }

  Future<CartResult?> getCachedCart() async {
    try {
      final raw = await _cache.getCache(_cacheKey);
      if (raw == null) return null;
      return CartResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;  // cache hỏng hoặc sai định dạng thì coi như chưa có
    }
  }
}