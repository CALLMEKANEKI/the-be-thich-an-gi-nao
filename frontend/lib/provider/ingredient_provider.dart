import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';
import '../services/ingredient_api_service.dart';

enum IngredientStatus { idle, loading, success, error }

class IngredientProvider extends ChangeNotifier {
  IngredientStatus _status = IngredientStatus.idle;
  List<Ingredient> _ingredients = [];
  String? _errorMessage;
  int _currentDishId = 0;

  final IngredientApiService _apiService = IngredientApiService();

  IngredientStatus get status => _status;
  List<Ingredient> get ingredients => _ingredients;
  String? get errorMessage => _errorMessage;
  int get currentDishId => _currentDishId;

  Future<void> fetchIngredients(int dishId) async {
    _currentDishId = dishId;
    _status = IngredientStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _ingredients = await _apiService.getIngredients(dishId);
      _status = IngredientStatus.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = IngredientStatus.error;
      notifyListeners();
    }
  }

  void reset() {
    _status = IngredientStatus.idle;
    _ingredients = [];
    _errorMessage = null;
    _currentDishId = 0;
    notifyListeners();
  }
}
