import 'package:flutter/foundation.dart';
import '../models/cart_result.dart';
import '../models/ingredient.dart';
import '../services/cart_api_service.dart';

enum CartStatus { idle, loading, success, error }

class CartProvider extends ChangeNotifier {
  CartStatus _status = CartStatus.idle;
  CartResult? _cart;
  bool _isFromCache = false;
  String? _errorMessage;

  final CartApiService _apiService = CartApiService();

  CartStatus get status => _status;
  CartResult? get cart => _cart;
  bool get isFromCache => _isFromCache;
  String? get errorMessage => _errorMessage;

  Future<void> createCart({
    required int dishId,
    required String dishName,
    required List<Ingredient> ingredients,
  }) async {
    _status = CartStatus.loading;
    _isFromCache = false;
    notifyListeners();

    try {
      _cart = await _apiService.createCart(
        dishId: dishId,
        dishName: dishName,
        ingredients: ingredients,
      );
      _status = CartStatus.success;
    } catch (e) {
      final cached = await _apiService.getCachedCart();
      if (cached != null) {
        _cart = cached;
        _isFromCache = true;
        _status = CartStatus.success;
      } else {
        _errorMessage = e.toString();
        _status = CartStatus.error;
      }
    }
    notifyListeners();
  }
}