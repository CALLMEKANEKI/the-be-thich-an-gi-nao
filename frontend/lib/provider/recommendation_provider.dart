import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/wheel_option.dart';
import '../services/spin_api_service.dart';

enum RecommendationStatus { idle, loading, success, error }

class RecommendationProvider extends ChangeNotifier {
  RecommendationStatus _status = RecommendationStatus.idle;
  List<WheelOption> _wheelOptions = [];
  WheelOption? _selectedOption;
  String? _errorMessage;

  final SpinApiService _apiService = SpinApiService();

  RecommendationStatus get status => _status;
  List<WheelOption> get wheelOption => _wheelOptions;
  WheelOption? get selectedOption => _selectedOption;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWheelOption(String text) async {
    _status = RecommendationStatus.loading; 
    _selectedOption = null;
    notifyListeners();

    try {
      _wheelOptions = await _apiService.getWheelOption(text);
      _status = RecommendationStatus.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = RecommendationStatus.error;
      notifyListeners();
    }
  }

  void spinWheel(){
    if (_wheelOptions.isEmpty) return;
    final randomIndex = Random().nextInt(_wheelOptions.length);
    _selectedOption = _wheelOptions[randomIndex];
    notifyListeners();
  }
}