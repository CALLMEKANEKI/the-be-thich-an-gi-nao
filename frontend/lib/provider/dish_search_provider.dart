import 'package:flutter/foundation.dart';
import '../models/dish_recommendation.dart';
import '../services/dish_api_service.dart';

enum DishSearchStatus { idle, loading, success, error }

class DishSearchProvider extends ChangeNotifier {
  final DishApiService _apiService = DishApiService();

  DishSearchStatus _status = DishSearchStatus.idle;
  String _query = '';
  String? _selectedCategory;
  List<DishRecommendation> _dishes = [];
  List<DishCategory> _categories = [];
  int _total = 0;
  String? _errorMessage;

  // Lịch sử tìm kiếm gần đây
  final List<String> _recentSearches = [
    'Bún bò Huế',
    'Cơm tấm sườn',
    'Pizza phô mai',
  ];

  DishSearchStatus get status => _status;
  String get query => _query;
  String? get selectedCategory => _selectedCategory;
  List<DishRecommendation> get dishes => _dishes;
  List<DishCategory> get categories => _categories;
  int get total => _total;
  String? get errorMessage => _errorMessage;
  List<String> get recentSearches => _recentSearches;

  bool get hasActiveSearch => _query.trim().isNotEmpty || (_selectedCategory != null && _selectedCategory != 'Tất cả');

  DishSearchProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (_) {
      // Bỏ qua lỗi danh mục nếu offline
    }
  }

  Future<void> search(String queryText) async {
    _query = queryText.trim();
    if (_query.isEmpty && (_selectedCategory == null || _selectedCategory == 'Tất cả')) {
      _status = DishSearchStatus.idle;
      _dishes = [];
      _total = 0;
      notifyListeners();
      return;
    }

    if (_query.isNotEmpty && !_recentSearches.contains(_query)) {
      _recentSearches.insert(0, _query);
      if (_recentSearches.length > 8) {
        _recentSearches.removeLast();
      }
    }

    _status = DishSearchStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.searchDishes(
        query: _query.isNotEmpty ? _query : null,
        category: _selectedCategory,
        limit: 50,
      );
      _dishes = result.items;
      _total = result.total;
      _status = DishSearchStatus.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = DishSearchStatus.error;
      notifyListeners();
    }
  }

  void selectCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    search(_query);
  }

  void clearSearch() {
    _query = '';
    _selectedCategory = null;
    _dishes = [];
    _total = 0;
    _status = DishSearchStatus.idle;
    notifyListeners();
  }

  void removeRecentSearch(String text) {
    _recentSearches.remove(text);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }
}
