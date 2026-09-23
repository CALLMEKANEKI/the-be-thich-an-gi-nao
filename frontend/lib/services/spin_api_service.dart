import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish_recommendation.dart';

class SpinApiService{
  final String _baseUrl = 'http://10.0.2.2:8000';

  Future<DishRecommendation> getRecommendation(String mood) async{
    final url = Uri.parse('$_baseUrl/api/v1/spin/recommend');
    final respone = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mood': mood})
    );

    if (respone.statusCode == 200){
      final Map<String, dynamic> jsonMap = jsonDecode(respone.body);
      return DishRecommendation.fromJson(jsonMap);
    }
    else {
      throw Exception('Exception: ${respone.statusCode}');
    }
  }


}