import '../services/simple_cache_service.dart';

class FavoritesService {
  static const _favoritesKey = 'favorites';
  final SimpleCacheService _cache;

  FavoritesService(this._cache);

  List<String> getFavorites() {
    return _cache.get<List<dynamic>>(_favoritesKey)?.cast<String>() ?? [];
  }

  Future<void> addFavorite(String productId) async {
    final favorites = getFavorites();
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await _cache.save(_favoritesKey, favorites);
    }
  }

  Future<void> removeFavorite(String productId) async {
    final favorites = getFavorites()..remove(productId);
    await _cache.save(_favoritesKey, favorites);
  }

  Future<void> clearFavorites() async {
    await _cache.delete(_favoritesKey);
  }

  bool isFavorite(String productId) {
    return getFavorites().contains(productId);
  }
}