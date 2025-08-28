import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';
import '../models/pagination_result.dart';
import '../utils/crashlytics_helper.dart';
import '../utils/firestore_optimizer.dart';
import '../utils/asset_optimizer.dart';
import 'cache_service.dart';
import '../services/search_service.dart';
import '../services/analytics_service.dart';

class ContentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CacheService _cacheService = CacheService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  final CollectionReference _contentCollection = 
      FirebaseFirestore.instance.collection('content');
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Upload content with file parameters
  Future<ContentModel?> uploadContentWithFiles({
    required File mediaFile,
    required String title,
    required String description,
    required double price,
    required ContentType contentType,
    required List<String> tags,
    required String category,
  }) async {
    if (_auth.currentUser == null) return null;
    
    try {
      _setLoading(true);
      
      final userId = _auth.currentUser!.uid;
      final contentId = const Uuid().v4();
      final fileExtension = mediaFile.path.split('.').last;
      
      // Log content upload attempt to Crashlytics
      await CrashlyticsHelper.log('Content upload started: $contentId');
      await CrashlyticsHelper.setCustomKey('content_upload_type', contentType.toString());
      
      // Upload media to Firebase Storage
      final storageRef = _storage.ref().child(
          'content/$userId/$contentId.$fileExtension');
      
      final uploadTask = storageRef.putFile(mediaFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Generate thumbnail for videos (simplified for now)
      String thumbnailUrl = downloadUrl;
      if (contentType == ContentType.video) {
        // In a real app, you would generate a thumbnail here
        // For now, we'll use the same URL
      }
      
      // Create content document in Firestore
      final contentModel = ContentModel(
        id: contentId,
        sellerId: userId,
        title: title,
        description: description,
        price: price,
        mediaUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        contentType: contentType,
        tags: tags,
        category: category,
        createdAt: DateTime.now(),
        views: 0,
        downloads: 0,
        favorites: 0,
        sellerName: _auth.currentUser?.displayName ?? '',
      );
      
      await _contentCollection.doc(contentId).set(contentModel.toMap());
      
      // Log successful content upload to Crashlytics
      await CrashlyticsHelper.log('Content upload successful: $contentId');
      
      return contentModel;
    } catch (e) {
      debugPrint('Error uploading content: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error uploading content'
      );
      
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Upload content with ContentModel and files
  Future<ContentModel?> uploadContent({
    required ContentModel content,
    required File contentFile,
    required File thumbnailFile,
  }) async {
    if (_auth.currentUser == null) return null;
    
    try {
      _setLoading(true);
      
      final userId = _auth.currentUser!.uid;
      final contentId = const Uuid().v4();
      
      // Upload content file to Firebase Storage
      final contentFileExtension = contentFile.path.split('.').last;
      final contentStorageRef = _storage.ref().child(
          'content/$userId/$contentId.$contentFileExtension');
      
      final contentUploadTask = contentStorageRef.putFile(contentFile);
      final contentSnapshot = await contentUploadTask.whenComplete(() {});
      final contentDownloadUrl = await contentSnapshot.ref.getDownloadURL();
      
      // Upload thumbnail file to Firebase Storage
      final thumbnailFileExtension = thumbnailFile.path.split('.').last;
      final thumbnailStorageRef = _storage.ref().child(
          'thumbnails/$userId/$contentId.$thumbnailFileExtension');
      
      final thumbnailUploadTask = thumbnailStorageRef.putFile(thumbnailFile);
      final thumbnailSnapshot = await thumbnailUploadTask.whenComplete(() {});
      final thumbnailDownloadUrl = await thumbnailSnapshot.ref.getDownloadURL();
      
      // Update content model with URLs and ID
      final updatedContent = content.copyWith(
        id: contentId,
        mediaUrl: contentDownloadUrl,
        thumbnailUrl: thumbnailDownloadUrl,
      );
      
      // Save to Firestore
      await _contentCollection.doc(contentId).set(updatedContent.toMap());
      
      return updatedContent;
    } catch (e) {
      debugPrint('Error uploading content: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get content by ID
  Future<ContentModel?> getContentById(String contentId) async {
    try {
      final doc = await _contentCollection.doc(contentId).get();
      
      if (doc.exists) {
        // Increment view count
        await _contentCollection.doc(contentId).update({
          'views': FieldValue.increment(1),
        });
        
        return ContentModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting content: $e');
      return null;
    }
  }
  
  // Get paginated content with optimized queries
  Future<PaginationResult<ContentModel>> getPaginatedContent({
    int limit = 10,
    String? startAfterId,
    String? category,
    ContentType? contentType,
    SortOption sortOption = SortOption.newest,
  }) async {
    try {
      // Create filters list
      final List<QueryFilter> filters = [];
      
      // Apply category filter if provided
      if (category != null && category.isNotEmpty) {
        filters.add(QueryFilter(
          field: 'category',
          operator: FilterOperator.isEqualTo,
          value: category,
        ));
      }
      
      // Apply content type filter if provided
      if (contentType != null) {
        filters.add(QueryFilter(
          field: 'contentType',
          operator: FilterOperator.isEqualTo,
          value: contentType.name,
        ));
      }
      
      // Create orders list based on the sort option
      final List<QueryOrder> orders = [];
      switch (sortOption) {
        case SortOption.newest:
          orders.add(QueryOrder(field: 'createdAt', descending: true));
          break;
        case SortOption.oldest:
          orders.add(QueryOrder(field: 'createdAt', descending: false));
          break;
        case SortOption.priceHighToLow:
          orders.add(QueryOrder(field: 'price', descending: true));
          break;
        case SortOption.priceLowToHigh:
          orders.add(QueryOrder(field: 'price', descending: false));
          break;
        case SortOption.popular:
          orders.add(QueryOrder(field: 'viewCount', descending: true));
          break;
      }
      
      // Get startAfter document if ID is provided
      DocumentSnapshot? startAfterDoc;
      if (startAfterId != null) {
        final docSnapshot = await _firestore.collection('content').doc(startAfterId).get();
        if (docSnapshot.exists) {
          startAfterDoc = docSnapshot;
        }
      }
      
      // Create optimized query using FirestoreOptimizer
      Query<Map<String, dynamic>> query = FirestoreOptimizer.createOptimizedQuery(
        collection: 'content',
        filters: filters,
        orders: orders,
        limit: limit + 1, // Get one extra to check if there are more
        startAfter: startAfterDoc,
      );
      
      // Execute query
      final querySnapshot = await query.get();
      
      // Check if there are more items
      bool hasMore = querySnapshot.docs.length > limit;
      
      // Remove the extra item if there are more
      final items = hasMore 
          ? querySnapshot.docs.sublist(0, limit)
          : querySnapshot.docs;
      
      // Get the last document ID
      final lastDocId = items.isNotEmpty ? items.last.id : null;
      
      // Convert to content models
      final contentList = items
          .map((doc) => ContentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      
      return PaginationResult<ContentModel>(
        items: contentList,
        lastDocumentId: lastDocId,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('Error getting paginated content: $e');
      return PaginationResult.empty();
    }
  }
  
  // Get content by seller ID
  Future<List<ContentModel>> getContentBySellerId(String sellerId) async {
    try {
      final querySnapshot = await _contentCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ContentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting seller content: $e');
      return [];
    }
  }
  
  // Get content created by the current user
  Future<List<ContentModel>> getMyContent() async {
    if (_auth.currentUser == null) return [];
    
    try {
      final userId = _auth.currentUser!.uid;
      return await getContentBySellerId(userId);
    } catch (e) {
      debugPrint('Error getting my content: $e');
      return [];
    }
  }
  
  // Get latest content
  Future<List<ContentModel>> getLatestContent({int limit = 20}) async {
    try {
      final querySnapshot = await _contentCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ContentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting latest content: $e');
      return [];
    }
  }
  
  // Search content
  Future<List<ContentModel>> searchContent({
    String? query,
    String? category,
    ContentType? contentType,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool descending = true,
  }) async {
    try {
      Query contentQuery = _contentCollection;
      
      // Apply filters
      if (category != null && category.isNotEmpty) {
        contentQuery = contentQuery.where('category', isEqualTo: category);
      }
      
      if (contentType != null) {
        contentQuery = contentQuery.where('contentType', 
            isEqualTo: contentTypeToString(contentType));
      }
      
      // Apply sorting
      if (sortBy != null && sortBy.isNotEmpty) {
        contentQuery = contentQuery.orderBy(sortBy, descending: descending);
      } else {
        contentQuery = contentQuery.orderBy('createdAt', descending: true);
      }
      
      final querySnapshot = await contentQuery.get();
      
      List<ContentModel> results = querySnapshot.docs
          .map((doc) => ContentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Apply price filters (client-side filtering)
      if (minPrice != null) {
        results = results.where((content) => content.price >= minPrice).toList();
      }
      
      if (maxPrice != null) {
        results = results.where((content) => content.price <= maxPrice).toList();
      }
      
      // Apply text search (client-side filtering)
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        results = results.where((content) {
          return content.title.toLowerCase().contains(lowercaseQuery) ||
              content.description.toLowerCase().contains(lowercaseQuery) ||
              content.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
        }).toList();
      }
      
      return results;
    } catch (e) {
      debugPrint('Error searching content: $e');
      return [];
    }
  }
  
  // Update content
  Future<bool> updateContent({
    required String contentId,
    String? title,
    String? description,
    double? price,
    List<String>? tags,
    String? category,
  }) async {
    if (_auth.currentUser == null) return false;
    
    try {
      _setLoading(true);
      
      final userId = _auth.currentUser!.uid;
      
      // Verify ownership
      final doc = await _contentCollection.doc(contentId).get();
      if (!doc.exists) return false;
      
      final content = ContentModel.fromMap(doc.data() as Map<String, dynamic>);
      if (content.sellerId != userId) return false;
      
      // Update fields
      final Map<String, dynamic> updates = {};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (tags != null) updates['tags'] = tags;
      if (category != null) updates['category'] = category;
      
      await _contentCollection.doc(contentId).update(updates);
      
      return true;
    } catch (e) {
      debugPrint('Error updating content: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete content
  Future<bool> deleteContent(String contentId) async {
    if (_auth.currentUser == null) return false;
    
    try {
      _setLoading(true);
      
      final userId = _auth.currentUser!.uid;
      
      // Verify ownership
      final doc = await _contentCollection.doc(contentId).get();
      if (!doc.exists) return false;
      
      final content = ContentModel.fromMap(doc.data() as Map<String, dynamic>);
      if (content.sellerId != userId) return false;
      
      // Delete from Storage
      final storageRef = _storage.refFromURL(content.mediaUrl);
      await storageRef.delete();
      
      // Delete from Firestore
      await _contentCollection.doc(contentId).delete();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting content: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Toggle favorite
  Future<bool> toggleFavorite({
    required String contentId,
    required String userId,
  }) async {
    if (userId.isEmpty) return false;
    
    try {
      // Check if already favorited
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      List<String> favorites = [];
      if (userData != null && userData.containsKey('favorites')) {
        favorites = List<String>.from(userData['favorites']);
      }
      
      bool isFavorited = favorites.contains(contentId);
      
      // Update user's favorites
      if (isFavorited) {
        favorites.remove(contentId);
        await _contentCollection.doc(contentId).update({
          'favorites': FieldValue.increment(-1),
        });
      } else {
        favorites.add(contentId);
        await _contentCollection.doc(contentId).update({
          'favorites': FieldValue.increment(1),
        });
      }
      
      await _usersCollection.doc(userId).update({
        'favorites': favorites,
      });
      
      // Track favorite action in analytics
      final contentDoc = await _contentCollection.doc(contentId).get();
      if (contentDoc.exists) {
        final content = ContentModel.fromFirestore(contentDoc);
        final analyticsService = AnalyticsService();
        await analyticsService.logFavoriteAction(
          contentId: contentId,
          contentTitle: content.title,
          isFavorited: !isFavorited,
        );
      }
      
      return !isFavorited; // Return new favorite state
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }
  
  // Add to favorites
  Future<bool> addToFavorites(String userId, String contentId) async {
    if (userId.isEmpty) return false;
    
    try {
      return await toggleFavorite(contentId: contentId, userId: userId);
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      return false;
    }
  }
  
  // Check if content is favorited by user
  Future<bool> isContentFavorited(String userId, String contentId) async {
    if (userId.isEmpty) return false;
    
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null || !userData.containsKey('favorites')) {
        return false;
      }
      
      final favorites = List<String>.from(userData['favorites']);
      return favorites.contains(contentId);
    } catch (e) {
      debugPrint('Error checking if content is favorited: $e');
      return false;
    }
  }
  
  // Remove from favorites
  Future<bool> removeFromFavorites(String userId, String contentId) async {
    if (userId.isEmpty) return false;
    
    try {
      // First check if it's already favorited
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      List<String> favorites = [];
      if (userData != null && userData.containsKey('favorites')) {
        favorites = List<String>.from(userData['favorites']);
      }
      
      // Only proceed if it's actually in favorites
      if (favorites.contains(contentId)) {
        return await toggleFavorite(contentId: contentId, userId: userId);
      }
      return true; // Already not in favorites
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      return false;
    }
  }
  
  // Get user's favorite content with optional content type filter
  Future<List<ContentModel>> getFavoriteContent({
    required String userId,
    ContentType? contentType,
  }) async {
    if (userId.isEmpty) return [];
    
    try {
      // Get user's favorites
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null || !userData.containsKey('favorites')) {
        return [];
      }
      
      final favorites = List<String>.from(userData['favorites']);
      
      if (favorites.isEmpty) {
        return [];
      }
      
      // Get content for each favorite ID
      final results = <ContentModel>[];
      
      for (final contentId in favorites) {
        final doc = await _contentCollection.doc(contentId).get();
        if (doc.exists) {
          final content = ContentModel.fromMap(doc.data() as Map<String, dynamic>);
          
          // Apply content type filter if specified
          if (contentType == null || content.contentType == contentType) {
            results.add(content);
          }
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting favorite content: $e');
      return [];
    }
  }
  
  // Purchase content
  Future<bool> purchaseContent(String contentId) async {
    if (_auth.currentUser == null) return false;
    
    try {
      _setLoading(true);
      
      final userId = _auth.currentUser!.uid;
      
      // Get content
      final contentDoc = await _contentCollection.doc(contentId).get();
      if (!contentDoc.exists) return false;
      
      final content = ContentModel.fromMap(contentDoc.data() as Map<String, dynamic>);
      
      // Check if already purchased
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      List<String> purchases = [];
      if (userData != null && userData.containsKey('purchases')) {
        purchases = List<String>.from(userData['purchases']);
      }
      
      if (purchases.contains(contentId)) {
        return true; // Already purchased
      }
      
      // In a real app, you would process payment here
      // For this example, we'll just record the purchase
      
      // Update user's purchases
      purchases.add(contentId);
      await _usersCollection.doc(userId).update({
        'purchases': purchases,
      });
      
      // Update content downloads
      await _contentCollection.doc(contentId).update({
        'downloads': FieldValue.increment(1),
      });
      
      // Record transaction
      await _firestore.collection('transactions').add({
        'buyerId': userId,
        'sellerId': content.sellerId,
        'contentId': contentId,
        'amount': content.price,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update seller's earnings
      await _usersCollection.doc(content.sellerId).update({
        'earnings': FieldValue.increment(content.price),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error purchasing content: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get purchased content
  Future<List<ContentModel>> getPurchasedContent() async {
    if (_auth.currentUser == null) return [];
    
    try {
      final userId = _auth.currentUser!.uid;
      
      // Get user's purchases
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null || !userData.containsKey('purchases')) {
        return [];
      }
      
      final purchases = List<String>.from(userData['purchases']);
      
      if (purchases.isEmpty) {
        return [];
      }
      
      // Get content for each purchase ID
      final results = <ContentModel>[];
      
      for (final contentId in purchases) {
        final doc = await _contentCollection.doc(contentId).get();
        if (doc.exists) {
          results.add(ContentModel.fromMap(doc.data() as Map<String, dynamic>));
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting purchased content: $e');
      return [];
    }
  }
  
  // Get seller analytics
  Future<Map<String, dynamic>> getSellerAnalytics({String period = 'week'}) async {
    if (_auth.currentUser == null) {
      return {
        'totalViews': 0,
        'totalDownloads': 0,
        'totalFavorites': 0,
        'totalEarnings': 0.0,
        'contentCount': 0,
        'totalSales': 0,
        'salesByContentType': {},
        'topSellingContent': [],
        'revenueData': [],
      };
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      
      // Get all content by seller
      final querySnapshot = await _contentCollection
          .where('sellerId', isEqualTo: userId)
          .get();
      
      final content = querySnapshot.docs
          .map((doc) => ContentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Calculate totals
      int totalViews = 0;
      int totalDownloads = 0;
      int totalFavorites = 0;
      
      for (final item in content) {
        totalViews += item.views;
        totalDownloads += item.downloads;
        totalFavorites += item.favorites;
      }
      
      // Get earnings
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      double totalEarnings = 0.0;
      if (userData != null && userData.containsKey('earnings')) {
        totalEarnings = (userData['earnings'] as num).toDouble();
      }
      
      // In a real app, you would filter data based on the period parameter
      // and generate more detailed analytics
      
      return {
        'totalViews': totalViews,
        'totalDownloads': totalDownloads,
        'totalFavorites': totalFavorites,
        'totalEarnings': totalEarnings,
        'contentCount': content.length,
        'totalSales': totalDownloads, // Using downloads as a proxy for sales in this example
        'salesByContentType': {}, // Would be populated in a real app
        'topSellingContent': [], // Would be populated in a real app
        'revenueData': [], // Would be populated in a real app
      };
    } catch (e) {
      debugPrint('Error getting seller analytics: $e');
      return {
        'totalViews': 0,
        'totalDownloads': 0,
        'totalFavorites': 0,
        'totalEarnings': 0.0,
        'contentCount': 0,
        'totalSales': 0,
        'salesByContentType': {},
        'topSellingContent': [],
        'revenueData': [],
      };
    }
  }
  
  // Helper method to convert ContentType enum to string
  String contentTypeToString(ContentType type) {
    switch (type) {
      case ContentType.image:
        return 'image';
      case ContentType.video:
        return 'video';
      case ContentType.gif:
        return 'gif';
      default:
        return 'image';
    }
  }
  
  // Helper method to convert string to ContentType enum
  ContentType stringToContentType(String type) {
    switch (type) {
      case 'image':
        return ContentType.image;
      case 'video':
        return ContentType.video;
      case 'gif':
        return ContentType.gif;
      // Handle legacy types for backward compatibility
      case 'audio':
      case 'document':
      case 'other':
      default:
        return ContentType.image;
    }
  }
}