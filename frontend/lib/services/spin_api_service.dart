import 'dart:convert';
import '../core/api_config.dart';
import '../models/wheel_option.dart';
import 'package:http/http.dart' as http;

class SpinApiService {
  Future<List<WheelOption>> getWheelOption(
    String text, {
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/spin/recommend');
    final Map<String, dynamic> body = {'text': text};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.aiTimeout);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      final List<dynamic> rawList = jsonMap['data']['wheel_options'];
      return rawList.map((item) => WheelOption.fromJson(item)).toList();
    } else {
      throw Exception('Lỗi server gợi ý: ${response.statusCode}');
    }
  }
}