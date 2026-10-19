import 'package:flutter/foundation.dart';
import '../models/nearby_place.dart';
import '../services/place_api_service.dart';

enum PlacesStatus { idle, loading, success, error }

class PlacesProvider extends ChangeNotifier {
  PlacesStatus _status = PlacesStatus.idle;
  List<NearbyPlace> _places = [];
  String? _errorMessage;
  String _currentDishName = '';
  int _requestToken = 0;

  final PlaceApiService _apiService = PlaceApiService();

  PlacesStatus get status => _status;
  List<NearbyPlace> get places => _places;
  String? get errorMessage => _errorMessage;
  String get currentDishName => _currentDishName;

  /// Prefetch danh sách quán ăn theo dishName và toạ độ.
  /// Sử dụng requestToken để huỷ kết quả cũ khi người dùng quay vào món khác.
  Future<void> prefetch({
    required String dishName,
    required double latitude,
    required double longitude,
    int radiusM = 3000,
    int limit = 20,
  }) async {
    _requestToken++;
    final int thisToken = _requestToken;

    _status = PlacesStatus.loading;
    _currentDishName = dishName;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.getNearbyPlaces(
        dishName: dishName,
        latitude: latitude,
        longitude: longitude,
        radiusM: radiusM,
        limit: limit,
      );

      // Nếu người dùng đã quay sang món khác trong lúc API đang tải, bỏ qua kết quả này
      if (thisToken != _requestToken) return;

      _places = results;
      _status = PlacesStatus.success;
      notifyListeners();
    } catch (e) {
      if (thisToken != _requestToken) return;

      _errorMessage = e.toString();
      _status = PlacesStatus.error;
      notifyListeners();
    }
  }

  Future<void> searchPlaces({
    required String dishName,
    required double latitude,
    required double longitude,
    int radiusM = 3000,
    int limit = 20,
  }) async {
    return prefetch(
      dishName: dishName,
      latitude: latitude,
      longitude: longitude,
      radiusM: radiusM,
      limit: limit,
    );
  }

  void reset() {
    _requestToken++;
    _status = PlacesStatus.idle;
    _places = [];
    _errorMessage = null;
    _currentDishName = '';
    notifyListeners();
  }
}
