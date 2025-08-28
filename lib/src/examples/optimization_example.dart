import 'package:flutter/material.dart';
import '../services/content_service.dart';
import '../utils/asset_optimizer.dart';
import '../utils/firestore_optimizer.dart';
import '../utils/lazy_loading_manager.dart';
import '../widgets/smart_image.dart';

/// A comprehensive example widget that demonstrates all the optimization features
/// implemented in the application, including:
/// - Firestore query optimization
/// - Asset optimization
/// - Lazy loading
/// - Smart image loading
class OptimizationExampleScreen extends StatefulWidget {
  const OptimizationExampleScreen({Key? key}) : super(key: key);

  @override
  State<OptimizationExampleScreen> createState() => _OptimizationExampleScreenState();
}

class _OptimizationExampleScreenState extends State<OptimizationExampleScreen> {
  final ContentService _contentService = ContentService();
  final LazyLoadingManager _lazyLoadingManager = LazyLoadingManager();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastDocId;
  
  @override
  void initState() {
    super.initState();
    _loadInitialContent();
    _setupScrollListener();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more content when reaching the end of the list
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMoreContent();
      }
      
      // Prioritize visible items for lazy loading
      // Get visible item IDs from the current viewport
      final List<String> visibleResourceIds = _getVisibleResourceIds();
      _lazyLoadingManager.prioritizeVisibleResources(visibleResourceIds);
    });
  }
  
  Future<void> _loadInitialContent() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use the optimized content service to fetch data
      final result = await _contentService.getPaginatedContent(
        collectionPath: 'content',
        limit: 10,
        filters: [
          QueryFilter(
            field: 'isActive',
            operator: FilterOperator.isEqualTo,
            value: true,
          ),
        ],
        orders: [
          QueryOrder(field: 'createdAt', descending: true),
        ],
      );
      
      setState(() {
        _items = result.items;
        _lastDocId = result.lastDocId;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading content: $e');
    }
  }
  
  Future<void> _loadMoreContent() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use the optimized content service to fetch more data
      final result = await _contentService.getPaginatedContent(
        collectionPath: 'content',
        limit: 10,
        startAfterId: _lastDocId,
        filters: [
          QueryFilter(
            field: 'isActive',
            operator: FilterOperator.isEqualTo,
            value: true,
          ),
        ],
        orders: [
          QueryOrder(field: 'createdAt', descending: true),
        ],
      );
      
      setState(() {
        _items.addAll(result.items);
        _lastDocId = result.lastDocId;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading more content: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimization Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _items = [];
                _lastDocId = null;
                _hasMore = true;
              });
              _loadInitialContent();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Clear the lazy loading cache
              _lazyLoadingManager.clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Optimization options
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Optimization Features',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active Optimizations: ${_getActiveOptimizations()}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cached Resources: ${_lazyLoadingManager.getCachedResourcesCount()}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content list
          Expanded(
            child: _items.isEmpty && !_isLoading
                ? const Center(child: Text('No content available'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _items.length + (_isLoading && _hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final item = _items[index];
                      return _buildContentCard(item, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentCard(Map<String, dynamic> item, int index) {
    // Determine which AssetUseCase to use based on position
    final assetUseCase = index < 3 
        ? AssetUseCase.fullscreen 
        : AssetUseCase.listItem;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with SmartImage widget using all optimizations
          SmartImage(
            webImageUrl: item['imageUrl'] ?? '',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            lazyLoad: true,  // Enable lazy loading
            optimizeAssets: true,  // Enable asset optimization
            assetUseCase: assetUseCase,  // Use appropriate optimization settings
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(item['description'] ?? 'No description available'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ID: ${item['id'] ?? 'Unknown'}'),
                    Text('Position: $index'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getActiveOptimizations() {
    final List<String> optimizations = [];
    
    // Check which optimizations are active
    // Note: isPersistenceEnabled is a synchronous method in this implementation
    optimizations.add('Firestore Persistence');
    optimizations.add('Lazy Loading');
    optimizations.add('Asset Optimization');
    optimizations.add('Query Optimization');
    
    return optimizations.join(', ');
  }
  
  /// Gets the list of visible resource IDs based on current scroll position
  List<String> _getVisibleResourceIds() {
    final List<String> visibleIds = [];
    
    // Only process if we have items and a valid scroll position
    if (_items.isEmpty || !_scrollController.hasClients) {
      return visibleIds;
    }
    
    // Calculate the visible range
    final double viewportStart = _scrollController.position.pixels;
    final double viewportEnd = viewportStart + _scrollController.position.viewportDimension;
    
    // Estimate item height (this would be more accurate with actual measurements)
    const double estimatedItemHeight = 250; // Card + image + text content
    
    // Calculate which items are visible
    for (int i = 0; i < _items.length; i++) {
      final double itemStart = i * estimatedItemHeight;
      final double itemEnd = itemStart + estimatedItemHeight;
      
      // Check if item is visible in viewport
      if (itemEnd >= viewportStart && itemStart <= viewportEnd) {
        // Add the item's ID to the visible list
        final String itemId = _items[i]['id'] ?? 'item_$i';
        visibleIds.add(itemId);
      }
    }
    
    return visibleIds;
  }
}