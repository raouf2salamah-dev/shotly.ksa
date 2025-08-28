import '../services/simple_cache_service.dart';

class RecentViewsService {
  static const _recentViewsKey = 'recent_views';
  final SimpleCacheService _cache;

  RecentViewsService(this._cache);

  List<String> getRecentViews() {
    return _cache.get<List<dynamic>>(_recentViewsKey)?.cast<String>() ?? [];
  }
  
  List<String> getAllRecentViews() {
    return getRecentViews();
  }

  Future<void> addRecentView(String productId) async {
    final recents = getRecentViews();
    recents.remove(productId); // avoid duplicates
    recents.insert(0, productId); // newest first
    if (recents.length > 20) recents.removeLast(); // limit size
    await _cache.save(_recentViewsKey, recents);
  }
  
  Future<void> removeRecentView(String itemId) async {
    final recents = getRecentViews();
    recents.remove(itemId);
    await _cache.save(_recentViewsKey, recents);
  }
  
  Future<void> clearAllRecentViews() async {
    await _cache.delete(_recentViewsKey);
  }
}