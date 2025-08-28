import 'package:flutter/foundation.dart';
import '../services/recent_views_service.dart';
import '../services/simple_cache_service.dart';

class RecentViewsProvider extends ChangeNotifier {
  final RecentViewsService _recentViewsService;
  final int maxRecentViews;

  RecentViewsProvider(this._recentViewsService, {this.maxRecentViews = 20});

  List<String> get recentViews => _recentViewsService.getAllRecentViews();

  void addRecentView(String itemId) {
    final current = _recentViewsService.getAllRecentViews();

    // Remove if already exists (to re-add at top)
    if (current.contains(itemId)) {
      _recentViewsService.removeRecentView(itemId);
    }

    // Purge oldest if limit reached
    if (current.length >= maxRecentViews) {
      final oldest = current.last;
      _recentViewsService.removeRecentView(oldest);
    }

    _recentViewsService.addRecentView(itemId);
    notifyListeners();
  }

  void removeRecentView(String itemId) {
    _recentViewsService.removeRecentView(itemId);
    notifyListeners();
  }

  void clearAllRecentViews() {
    _recentViewsService.clearAllRecentViews();
    notifyListeners();
  }
}