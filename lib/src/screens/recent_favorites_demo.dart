import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/recent_views_provider.dart';

class RecentFavoritesDemoScreen extends StatelessWidget {
  const RecentFavoritesDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final recentViewsProvider = Provider.of<RecentViewsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent & Favorites Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: () {
              favoritesProvider.clearAllFavorites();
              recentViewsProvider.clearAllRecentViews();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared all favorites and recent views')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Favorites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...favoritesProvider.favorites.map(
                  (itemId) => ListTile(
                    title: Text('Item $itemId'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => favoritesProvider.removeFavorite(itemId),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Recent Views', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...recentViewsProvider.recentViews.map(
                  (itemId) => ListTile(
                    title: Text('Item $itemId'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => recentViewsProvider.removeRecentView(itemId),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('Favorites Count: ${favoritesProvider.favorites.length}'),
                Text('Recent Views Count: ${recentViewsProvider.recentViews.length}'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Add Test Item',
        onPressed: () {
          // Add sample items for testing offline behavior
          final newItemId = DateTime.now().millisecondsSinceEpoch.toString();
          favoritesProvider.addFavorite(newItemId);
          recentViewsProvider.addRecentView(newItemId);

          // Optional analytics tracking (simple console log)
          print('Analytics: Added item $newItemId to Favorites & Recent Views');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added item $newItemId')),
          );
        },
      ),
    );
  }
}