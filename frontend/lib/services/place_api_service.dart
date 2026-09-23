import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nearby_place.dart';

class PlaceApiService {
  final String _baseUrl = 'http://10.0.2.2:8000';

  Future<List<NearbyPlace>> getNearbyPlaces({
    required String dishName,
    required double latitude,
    required double longitude,
    int radiusM = 3000,
    int limit = 20,
  }) async{
    final url = Uri.parse('$_baseUrl/api/v1/places/nearby');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'dish_name': dishName,
        'latitude': latitude,
        'longitude': longitude,
        'radius_m': radiusM,
        'limit': limit,
      }),
    );
    if (response.statusCode == 200){
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      final List<dynamic> rawList = jsonMap['data'];
      return rawList.map((item) => NearbyPlace.fromJson(item)).toList();
    }
    else{
      throw Exception('Exception ${response.statusCode}');
    }
  }
}