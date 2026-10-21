import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/wheel_option.dart';
import '../services/spin_api_service.dart';

enum RecommendationStatus { idle, loading, success, error }

class RecommendationProvider extends ChangeNotifier {
  RecommendationStatus _status = RecommendationStatus.idle;
  List<WheelOption> _wheelOptions = [];
  WheelOption? _selectedOption;
  int? _selectedIndex;
  String? _errorMessage;

  final SpinApiService _apiService = SpinApiService();

  RecommendationStatus get status => _status;
  List<WheelOption> get wheelOptions => _wheelOptions;
  List<WheelOption> get wheelOption => _wheelOptions; // giữ tương thích code cũ
  WheelOption? get selectedOption => _selectedOption;
  int? get selectedIndex => _selectedIndex;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWheelOption(
    String text, {
    double? latitude,
    double? longitude,
  }) async {
    _status = RecommendationStatus.loading;
    _selectedOption = null;
    _selectedIndex = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _wheelOptions = await _apiService.getWheelOption(
        text,
        latitude: latitude,
        longitude: longitude,
      );
      _status = RecommendationStatus.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = RecommendationStatus.error;
      notifyListeners();
    }
  }

  /// Random trước 1 index món ăn (0..total-1) theo quy định của Handoff Guide
  int pickRandomIndex() {
    if (_wheelOptions.isEmpty) return 0;
    final index = Random().nextInt(_wheelOptions.length);
    _selectedIndex = index;
    _selectedOption = _wheelOptions[index];
    notifyListeners();
    return index;
  }

  void selectDishByIndex(int index) {
    if (index >= 0 && index < _wheelOptions.length) {
      _selectedIndex = index;
      _selectedOption = _wheelOptions[index];
      notifyListeners();
    }
  }

  void spinWheel() {
    pickRandomIndex();
  }
}