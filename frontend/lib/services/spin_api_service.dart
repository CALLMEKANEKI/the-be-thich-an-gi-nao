import 'dart:convert';
import 'package:frontend/models/wheel_option.dart';
import 'package:http/http.dart' as http;

class SpinApiService{
  final String _baseUrl = 'http://10.0.2.2:8000';

  Future<List<WheelOption>> getWheelOption(String text) async{
    final url = Uri.parse('$_baseUrl/api/v1/spin/recommend');
    final respone = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text})
    );

    if (respone.statusCode == 200){
      final Map<String, dynamic> jsonMap = jsonDecode(respone.body);
      final List<dynamic> rawList = jsonMap['data']['wheel_options'];
      return rawList.map((item) => WheelOption.fromJson(item)).toList();
    }
    else {
      throw Exception('Exception: ${respone.statusCode}');
    }
  }


}