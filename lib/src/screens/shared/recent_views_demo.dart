import 'package:flutter/material.dart';
import '../../services/recent_views_service.dart';
import '../../services/simple_cache_service.dart';

class RecentViewsDemo extends StatefulWidget {
  const RecentViewsDemo({Key? key}) : super(key: key);

  @override
  State<RecentViewsDemo> createState() => _RecentViewsDemoState();
}

class _RecentViewsDemoState extends State<RecentViewsDemo> {
  final TextEditingController _productIdController = TextEditingController();
  late final SimpleCacheService _cacheService;
  late final RecentViewsService _recentViewsService;
  List<String> _recentViews = [];
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
      _recentViewsService = RecentViewsService(_cacheService);
      _loadRecentViews();
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

  void _loadRecentViews() {
    setState(() {
      _recentViews = _recentViewsService.getRecentViews();
    });
  }

  Future<void> _addRecentView() async {
    final productId = _productIdController.text.trim();

    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID cannot be empty')),
      );
      return;
    }

    try {
      await _recentViewsService.addRecentView(productId);
      _productIdController.clear();
      _loadRecentViews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $productId to recent views')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding recent view: $e')),
      );
    }
  }

  Future<void> _clearRecentViews() async {
    try {
      await _cacheService.delete('recent_views');
      _loadRecentViews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cleared all recent views')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing recent views: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Views Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearRecentViews,
            tooltip: 'Clear all recent views',
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
                          const Text(
                            'Add Product to Recent Views',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _productIdController,
                            decoration: const InputDecoration(
                              labelText: 'Product ID',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addRecentView,
                            child: const Text('Add to Recent Views'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recent Views (${_recentViews.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _recentViews.isEmpty
                        ? const Center(
                            child: Text('No recent views yet'),
                          )
                        : ListView.builder(
                            itemCount: _recentViews.length,
                            itemBuilder: (context, index) {
                              final productId = _recentViews[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(productId),
                                  subtitle: Text('Position: ${index + 1}'),
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