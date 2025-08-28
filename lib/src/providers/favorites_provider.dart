import 'package:flutter/foundation.dart';
import '../services/favorites_service.dart';
import '../services/simple_cache_service.dart';

class FavoritesProvider extends ChangeNotifier {
  late final SimpleCacheService _cacheService;
  late final FavoritesService _favoritesService;
  List<String> _favorites = [];
  bool _isInitialized = false;

  FavoritesProvider() {
    _init();
  }

  List<String> get favorites => _favorites;
  bool get isInitialized => _isInitialized;

  Future<void> _init() async {
    _cacheService = SimpleCacheService(maxItems: 50);
    await _cacheService.init();
    _favoritesService = FavoritesService(_cacheService);
    _loadFavorites();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadFavorites() {
    _favorites = _favoritesService.getFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(String productId) async {
    await _favoritesService.addFavorite(productId);
    _loadFavorites();
  }

  Future<void> removeFavorite(String productId) async {
    await _favoritesService.removeFavorite(productId);
    _loadFavorites();
  }

  Future<void> clearFavorites() async {
    await _favoritesService.clearFavorites();
    _loadFavorites();
  }
  
  Future<void> clearAllFavorites() async {
    await clearFavorites();
  }

  bool isFavorite(String productId) {
    return _favoritesService.isFavorite(productId);
  }
}