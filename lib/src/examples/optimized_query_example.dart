import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/firestore_optimizer.dart';
import '../models/content_model.dart';
import '../widgets/content_card.dart';

class OptimizedQueryExample extends StatefulWidget {
  const OptimizedQueryExample({super.key});

  @override
  State<OptimizedQueryExample> createState() => _OptimizedQueryExampleState();
}

class _OptimizedQueryExampleState extends State<OptimizedQueryExample> {
  final List<ContentModel> _items = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadBundle();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Load bundle for frequently accessed data
  Future<void> _loadBundle() async {
    await FirestoreOptimizer.loadBundle('products_bundle');
  }
  
  // Scroll listener for infinite scrolling
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreData();
      }
    }
  }
  
  // Load initial data with optimized query
  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create optimized query with FirestoreOptimizer
      final query = FirestoreOptimizer.createOptimizedQuery(
        collection: 'products',
        filters: [
          QueryFilter(
            field: 'category',
            operator: FilterOperator.isEqualTo,
            value: 'electronics',
          ),
        ],
        orders: [
          QueryOrder(
            field: 'price',
            descending: false,
          ),
        ],
        limit: 20,
      );
      
      // Try to get from cache first for faster loading
      final querySnapshot = await query.get(GetOptions(source: Source.serverAndCache));
      
      final items = querySnapshot.docs
          .map((doc) => ContentModel.fromFirestore(doc))
          .toList();
      
      if (mounted) {
        setState(() {
          _items.clear();
          _items.addAll(items);
          _isLoading = false;
          
          if (querySnapshot.docs.isNotEmpty) {
            _lastDocument = querySnapshot.docs.last;
          } else {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load more data for pagination
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create optimized query with pagination
      final query = FirestoreOptimizer.createOptimizedQuery(
        collection: 'products',
        filters: [
          QueryFilter(
            field: 'category',
            operator: FilterOperator.isEqualTo,
            value: 'electronics',
          ),
        ],
        orders: [
          QueryOrder(
            field: 'price',
            descending: false,
          ),
        ],
        limit: 20,
        startAfter: _lastDocument,
      );
      
      final querySnapshot = await query.get();
      
      final items = querySnapshot.docs
          .map((doc) => ContentModel.fromFirestore(doc))
          .toList();
      
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _isLoading = false;
          
          if (querySnapshot.docs.isNotEmpty) {
            _lastDocument = querySnapshot.docs.last;
          } else {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading more data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Query Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Showing ${_items.length} items with pagination',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: _items.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No items found'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _items.length + (_hasMoreData ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _items.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          final item = _items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: ContentCard(
                              content: item,
                              onTap: () {},
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}