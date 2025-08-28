import 'package:flutter/material.dart';
import '../../services/favorites_service.dart';
import '../../services/simple_cache_service.dart';

class FavoritesDemo extends StatefulWidget {
  const FavoritesDemo({Key? key}) : super(key: key);

  @override
  State<FavoritesDemo> createState() => _FavoritesDemoState();
}

class _FavoritesDemoState extends State<FavoritesDemo> {
  final TextEditingController _productIdController = TextEditingController();
  late final SimpleCacheService _cacheService;
  late final FavoritesService _favoritesService;
  List<String> _favorites = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  @override
  void dispose() {
    _productIdController.dispose();
    super.dispose();
  }

  Future<void> _initServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _cacheService = SimpleCacheService(maxItems: 50);
      await _cacheService.init();
      _favoritesService = FavoritesService(_cacheService);
      _loadFavorites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing services: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadFavorites() {
    setState(() {
      _favorites = _favoritesService.getFavorites();
    });
  }

  Future<void> _addFavorite() async {
    final productId = _productIdController.text.trim();

    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID cannot be empty')),
      );
      return;
    }

    try {
      await _favoritesService.addFavorite(productId);
      _productIdController.clear();
      _loadFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $productId to favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding favorite: $e')),
      );
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      await _favoritesService.removeFavorite(productId);
      _loadFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $productId from favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing favorite: $e')),
      );
    }
  }

  Future<void> _clearFavorites() async {
    try {
      await _favoritesService.clearFavorites();
      _loadFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cleared all favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearFavorites,
            tooltip: 'Clear all favorites',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _productIdController,
                            decoration: const InputDecoration(
                              labelText: 'Product ID',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addFavorite,
                            child: const Text('Add to Favorites'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Favorites (${_favorites.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _favorites.isEmpty
                        ? const Center(
                            child: Text('No favorites yet'),
                          )
                        : ListView.builder(
                            itemCount: _favorites.length,
                            itemBuilder: (context, index) {
                              final productId = _favorites[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(productId),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeFavorite(productId),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}