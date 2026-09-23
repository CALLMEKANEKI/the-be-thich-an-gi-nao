import 'package:flutter/foundation.dart';
import '../models/dish_recommendation.dart';
import '../services/spin_api_service.dart';

enum RecommendationStatus { idle, loading, success, error }

class RecommendationProvider extends ChangeNotifier {
  RecommendationStatus _status = RecommendationStatus.idle;
  DishRecommendation? _dish;
  String? _errorMessage;

  final SpinApiService _apiService = SpinApiService();

  RecommendationStatus get status => _status;
  DishRecommendation? get dish => _dish;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecommendation(String mood) async {
    _status = RecommendationStatus.loading;
    notifyListeners();

    try {
      _dish = await _apiService.getRecommendation(mood);
      _status = RecommendationStatus.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = RecommendationStatus.error;
      notifyListeners();
    }
  }
}