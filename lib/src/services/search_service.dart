import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show GetOptions, Source;

import '../models/content_model.dart';

class SearchService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Search results
  List<ContentModel> _searchResults = [];
  List<ContentModel> get searchResults => _searchResults;
  
  // Search state
  bool _isSearching = false;
  bool get isSearching => _isSearching;
  
  // Pagination state
  bool _hasMoreContent = true;
  bool get hasMoreContent => _hasMoreContent;
  
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  
  // Filter state
  ContentType? _selectedContentType;
  ContentType? get selectedContentType => _selectedContentType;
  
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;
  
  SortOption _sortOption = SortOption.newest;
  SortOption get sortOption => _sortOption;
  
  PriceRange _priceRange = PriceRange.all;
  PriceRange get priceRange => _priceRange;
  
  // Available categories
  List<String> _availableCategories = [];
  List<String> get availableCategories => _availableCategories;
  
  SearchService() {
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    try {
      final categoriesDoc = await _firestore.collection('metadata').doc('categories').get();
      if (categoriesDoc.exists) {
        final categories = categoriesDoc.data()?['categories'] as List<dynamic>?;
        if (categories != null) {
          _availableCategories = List<String>.from(categories);
        } else {
          _availableCategories = _getDefaultCategories();
        }
      } else {
        _availableCategories = _getDefaultCategories();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      _availableCategories = _getDefaultCategories();
      notifyListeners();
    }
  }
  
  List<String> _getDefaultCategories() {
    return [
      'Nature',
      'People',
      'Architecture',
      'Animals',
      'Travel',
      'Food',
      'Sports',
      'Technology',
      'Art',
      'Fashion',
      'Business',
      'Education',
      'Entertainment',
      'Health',
      'Other',
    ];
  }
  
  Future<void> searchContent(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    
    try {
      _isSearching = true;
      notifyListeners();
      
      // Convert query to lowercase for case-insensitive search
      final lowercaseQuery = query.toLowerCase();
      
      // Start with a base query on the content collection
      Query contentQuery = _firestore.collection('content');
      
      // Apply content type filter if selected
      if (_selectedContentType != null) {
        contentQuery = contentQuery.where('contentType', isEqualTo: _selectedContentType!.name);
      }
      
      // Apply category filter if selected
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        contentQuery = contentQuery.where('category', isEqualTo: _selectedCategory);
      }
      
      // Apply price range filter
      if (_priceRange != PriceRange.all) {
        switch (_priceRange) {
          case PriceRange.free:
            contentQuery = contentQuery.where('price', isEqualTo: 0);
            break;
          case PriceRange.under5:
            contentQuery = contentQuery.where('price', isLessThanOrEqualTo: 5);
            break;
          case PriceRange.under10:
            contentQuery = contentQuery.where('price', isLessThanOrEqualTo: 10);
            break;
          case PriceRange.under20:
            contentQuery = contentQuery.where('price', isLessThanOrEqualTo: 20);
            break;
          case PriceRange.over20:
            contentQuery = contentQuery.where('price', isGreaterThan: 20);
            break;
          default:
            break;
        }
      }
      
      // Apply sorting
      switch (_sortOption) {
        case SortOption.newest:
          contentQuery = contentQuery.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldest:
          contentQuery = contentQuery.orderBy('createdAt', descending: false);
          break;
        case SortOption.priceHighToLow:
          contentQuery = contentQuery.orderBy('price', descending: true);
          break;
        case SortOption.priceLowToHigh:
          contentQuery = contentQuery.orderBy('price', descending: false);
          break;
        case SortOption.popular:
          contentQuery = contentQuery.orderBy('viewCount', descending: true);
          break;
      }
      
      // Execute the query
      final querySnapshot = await contentQuery.get();
      
      // Filter results by title, description, and tags that match the query
      List<ContentModel> results = [];
      for (var doc in querySnapshot.docs) {
        final content = ContentModel.fromFirestore(doc);
        
        // Check if title, description, or tags contain the query
        final titleMatches = content.title.toLowerCase().contains(lowercaseQuery);
        final descriptionMatches = content.description.toLowerCase().contains(lowercaseQuery);
        
        bool tagsMatch = false;
        for (var tag in content.tags) {
          if (tag.toLowerCase().contains(lowercaseQuery)) {
            tagsMatch = true;
            break;
          }
        }
        
        if (titleMatches || descriptionMatches || tagsMatch) {
          results.add(content);
        }
      }
      
      _searchResults = results;
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching content: $e');
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
    }
  }
  
  Future<void> getRecentContent({bool refresh = true}) async {
    try {
      if (refresh) {
        _isSearching = true;
        _lastDocument = null;
        _hasMoreContent = true;
        notifyListeners();
      } else if (_isLoadingMore || !_hasMoreContent) {
        // Don't load more if already loading or no more content
        return;
      } else {
        _isLoadingMore = true;
        notifyListeners();
      }
      
      // Start with a base query on the content collection
      Query contentQuery = _firestore.collection('content');
      
      // Apply content type filter if selected
      if (_selectedContentType != null) {
        contentQuery = contentQuery.where('contentType', isEqualTo: _selectedContentType!.name);
      }
      
      // Apply category filter if selected
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        contentQuery = contentQuery.where('category', isEqualTo: _selectedCategory);
      }
      
      // Apply price range filter
      if (_priceRange != PriceRange.all) {
        switch (_priceRange) {
          case PriceRange.free:
            contentQuery = contentQuery.where('price', isEqualTo: 0);
            break;
          case PriceRange.under5:
            contentQuery = contentQuery.where('price', isLessThanOrEqualTo: 5);
            break;
          case PriceRange.under10:
            contentQuery = contentQuery.where('price', isLessThanOrEqualTo: 10);
            break;
          case PriceRange.under20:
            contentQuery = contentQuery.where('price', isLessThanOrEqualTo: 20);
            break;
          case PriceRange.over20:
            contentQuery = contentQuery.where('price', isGreaterThan: 20);
            break;
          default:
            break;
        }
      }
      
      // Apply sorting
      switch (_sortOption) {
        case SortOption.newest:
          contentQuery = contentQuery.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldest:
          contentQuery = contentQuery.orderBy('createdAt', descending: false);
          break;
        case SortOption.priceHighToLow:
          contentQuery = contentQuery.orderBy('price', descending: true);
          break;
        case SortOption.priceLowToHigh:
          contentQuery = contentQuery.orderBy('price', descending: false);
          break;
        case SortOption.popular:
          contentQuery = contentQuery.orderBy('viewCount', descending: true);
          break;
      }
      
      // Apply pagination
      if (_lastDocument != null) {
        contentQuery = contentQuery.startAfterDocument(_lastDocument!);
      }
      
      // Limit the number of results per page
      contentQuery = contentQuery.limit(20);
      
      // Try to get from cache first for faster loading
      final querySnapshot = await contentQuery.get(GetOptions(source: Source.serverAndCache));
      
      // Update pagination state
      if (querySnapshot.docs.isEmpty) {
        _hasMoreContent = false;
      } else {
        _lastDocument = querySnapshot.docs.last;
      }
      
      // Convert documents to ContentModel objects
      List<ContentModel> results = [];
      for (var doc in querySnapshot.docs) {
        results.add(ContentModel.fromFirestore(doc));
      }
      
      // Update search results
      if (refresh) {
        _searchResults = results;
      } else {
        _searchResults.addAll(results);
      }
      
      _isSearching = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting recent content: $e');
      if (refresh) {
        _searchResults = [];
      }
      _isSearching = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  // Load more content (pagination)
  Future<void> loadMoreContent() async {
    if (!_isLoadingMore && _hasMoreContent) {
      await getRecentContent(refresh: false);
    }
  }
  
  Future<List<ContentModel>> getTrendingContent() async {
    try {
      // Query for trending content (most viewed in the last week)
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final querySnapshot = await _firestore
          .collection('content')
          .where('createdAt', isGreaterThan: oneWeekAgo)
          .orderBy('createdAt', descending: true)
          .orderBy('viewCount', descending: true)
          .limit(10)
          .get();
      
      // Convert documents to ContentModel objects
      List<ContentModel> results = [];
      for (var doc in querySnapshot.docs) {
        results.add(ContentModel.fromFirestore(doc));
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting trending content: $e');
      return [];
    }
  }
  
  Future<List<ContentModel>> getRecommendedContent(String userId) async {
    try {
      // Get user's favorite content types and categories
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      List<String> favoriteContentTypes = [];
      String? favoriteCategory;
      
      if (userDoc.exists) {
        // Get user's purchase history
        final purchases = userDoc.data()?['purchases'] as List<dynamic>? ?? [];
        
        // Get content details for purchases
        if (purchases.isNotEmpty) {
          // Get the last 5 purchases
          final recentPurchases = purchases.length > 5 
              ? purchases.sublist(purchases.length - 5) 
              : purchases;
          
          // Get content details for recent purchases
          for (var contentId in recentPurchases) {
            final contentDoc = await _firestore.collection('content').doc(contentId.toString()).get();
            if (contentDoc.exists) {
              final contentType = contentDoc.data()?['contentType'] as String?;
              final category = contentDoc.data()?['category'] as String?;
              
              if (contentType != null && !favoriteContentTypes.contains(contentType)) {
                favoriteContentTypes.add(contentType);
              }
              
              if (category != null && favoriteCategory == null) {
                favoriteCategory = category;
              }
            }
          }
        }
      }
      
      // Build query based on user preferences
      Query contentQuery = _firestore.collection('content');
      
      // If we have favorite content types, prioritize those
      if (favoriteContentTypes.isNotEmpty) {
        contentQuery = contentQuery.where('contentType', whereIn: favoriteContentTypes);
      }
      
      // If we have a favorite category, prioritize that
      if (favoriteCategory != null) {
        contentQuery = contentQuery.where('category', isEqualTo: favoriteCategory);
      }
      
      // Order by popularity
      contentQuery = contentQuery.orderBy('viewCount', descending: true);
      
      // Limit the number of results
      contentQuery = contentQuery.limit(10);
      
      // Execute the query
      final querySnapshot = await contentQuery.get();
      
      // Convert documents to ContentModel objects
      List<ContentModel> results = [];
      for (var doc in querySnapshot.docs) {
        results.add(ContentModel.fromFirestore(doc));
      }
      
      // If we don't have enough results, get some popular content
      if (results.length < 10) {
        final additionalResults = await getTrendingContent();
        
        // Add additional results, avoiding duplicates
        for (var content in additionalResults) {
          if (!results.any((item) => item.id == content.id)) {
            results.add(content);
            if (results.length >= 10) break;
          }
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting recommended content: $e');
      return [];
    }
  }
  
  void setContentTypeFilter(ContentType? contentType) {
    _selectedContentType = contentType;
    notifyListeners();
  }
  
  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }
  
  void setPriceRange(PriceRange range) {
    _priceRange = range;
    notifyListeners();
  }
  
  void clearFilters() {
    _selectedContentType = null;
    _selectedCategory = null;
    _sortOption = SortOption.newest;
    _priceRange = PriceRange.all;
    notifyListeners();
  }
}

enum SortOption {
  newest,
  oldest,
  priceHighToLow,
  priceLowToHigh,
  popular,
}

enum PriceRange {
  all,
  free,
  under5,
  under10,
  under20,
  over20,
}