import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/dish_recommendation.dart';

class DishCategory {
  final String name;
  final int count;

  DishCategory({required this.name, required this.count});

  factory DishCategory.fromJson(Map<String, dynamic> json) {
    return DishCategory(
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DishSearchResult {
  final int total;
  final int limit;
  final int offset;
  final List<DishRecommendation> items;

  DishSearchResult({
    required this.total,
    required this.limit,
    required this.offset,
    required this.items,
  });

  factory DishSearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return DishSearchResult(
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      items: rawItems.map((item) => DishRecommendation.fromJson(item)).toList(),
    );
  }
}

class DishApiService {
  /// Tìm kiếm danh sách món ăn từ Backend: GET /api/v1/dishes
  Future<DishSearchResult> searchDishes({
    String? query,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParameters = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParameters['q'] = query.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'Tất cả') {
      queryParameters['category'] = category.trim();
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/dishes')
        .replace(queryParameters: queryParameters);

    final response = await http
        .get(url, headers: {'Content-Type': 'application/json'})
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true && body['data'] != null) {
        return DishSearchResult.fromJson(body['data']);
      }
      return DishSearchResult(total: 0, limit: limit, offset: offset, items: []);
    } else {
      throw Exception('Lỗi lấy danh sách món ăn (${response.statusCode})');
    }
  }

  /// Lấy danh mục món ăn: GET /api/v1/dishes/categories
  Future<List<DishCategory>> getCategories() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/dishes/categories');

    final response = await http
        .get(url, headers: {'Content-Type': 'application/json'})
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true && body['data'] != null) {
        final List<dynamic> list = body['data'];
        return list.map((item) => DishCategory.fromJson(item)).toList();
      }
      return [];
    } else {
      throw Exception('Lỗi lấy danh mục món ăn (${response.statusCode})');
    }
  }

  /// Lấy chi tiết món ăn: GET /api/v1/dishes/{dish_id}
  Future<DishRecommendation?> getDishDetail(int dishId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/dishes/$dishId');

    final response = await http
        .get(url, headers: {'Content-Type': 'application/json'})
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true && body['data'] != null) {
        return DishRecommendation.fromJson(body['data']);
      }
      return null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Lỗi lấy chi tiết món ăn (${response.statusCode})');
    }
  }
}
