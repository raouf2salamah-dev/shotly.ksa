import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'hive_service.dart';

class CacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache collection data with Hive
  Future<List<Map<String, dynamic>>> getCollectionData(String collectionPath) async {
    final cacheKey = 'collection_$collectionPath';
    
    try {
      // Try to get data from cache first
      final cachedData = await HiveService.getFromCache(cacheKey);
      
      if (cachedData != null) {
        // If we have cached data, parse and return it
        print('💾 Using cached data for $collectionPath');
        return _parseJsonList(cachedData);
      }
      
      // If no cache or cache expired, fetch from Firestore
      print('🔄 Fetching fresh data for $collectionPath');
      final snapshot = await _firestore.collection(collectionPath).get();
      final data = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Cache the new data
      await HiveService.saveToCache(cacheKey, _listToJson(data));
      
      return data;
    } catch (e) {
      print('Error getting collection data: $e');
      // If there was an error, try to return cached data as fallback
      final cachedData = await HiveService.getFromCache(cacheKey);
      if (cachedData != null) {
        print('⚠️ Using cached data after error');
        return _parseJsonList(cachedData);
      }
      // If no cache available, rethrow the error
      rethrow;
    }
  }
  
  // Cache document data with Hive
  Future<Map<String, dynamic>?> getDocumentData(String documentPath) async {
    final cacheKey = 'document_$documentPath';
    
    try {
      // Try to get data from cache first
      final cachedData = await HiveService.getFromCache(cacheKey);
      
      if (cachedData != null) {
        // If we have cached data, parse and return it
        print('💾 Using cached data for $documentPath');
        return _parseJson(cachedData);
      }
      
      // If no cache or cache expired, fetch from Firestore
      print('🔄 Fetching fresh data for $documentPath');
      final docRef = _firestore.doc(documentPath);
      final snapshot = await docRef.get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      final data = {
        'id': snapshot.id,
        ...snapshot.data()!,
      };
      
      // Cache the new data
      await HiveService.saveToCache(cacheKey, _mapToJson(data));
      
      return data;
    } catch (e) {
      print('Error getting document data: $e');
      // If there was an error, try to return cached data as fallback
      final cachedData = await HiveService.getFromCache(cacheKey);
      if (cachedData != null) {
        print('⚠️ Using cached data after error');
        return _parseJson(cachedData);
      }
      // If no cache available, rethrow the error
      rethrow;
    }
  }
  
  // Save document data to Firestore and cache
  Future<void> saveDocumentData(String documentPath, Map<String, dynamic> data) async {
    final cacheKey = 'document_$documentPath';
    
    try {
      // Save to Firestore
      final docRef = _firestore.doc(documentPath);
      await docRef.set(data, SetOptions(merge: true));
      
      // Update cache
      final updatedData = {
        'id': docRef.id,
        ...data,
      };
      await HiveService.saveToCache(cacheKey, _mapToJson(updatedData));
      
      // Also invalidate any collection caches that might contain this document
      final collectionPath = documentPath.substring(0, documentPath.lastIndexOf('/'));
      final collectionCacheKey = 'collection_$collectionPath';
      await HiveService.deleteFromCache(collectionCacheKey);
      
    } catch (e) {
      print('Error saving document data: $e');
      rethrow;
    }
  }
  
  // Helper methods for JSON conversion
  String _listToJson(List<Map<String, dynamic>> list) {
    return list.map((item) => _mapToJson(item)).toList().toString();
  }
  
  String _mapToJson(Map<String, dynamic> map) {
    final jsonMap = {};
    map.forEach((key, value) {
      // Convert Timestamps to ISO strings
      if (value is Timestamp) {
        jsonMap[key] = value.toDate().toIso8601String();
      } else {
        jsonMap[key] = value;
      }
    });
    return jsonMap.toString();
  }
  
  List<Map<String, dynamic>> _parseJsonList(String jsonString) {
    // This is a simplified implementation
    // In a real app, you would use a proper JSON parser
    try {
      // For demo purposes only
      return [{'id': 'cached-1', 'name': 'Cached Item 1'}, {'id': 'cached-2', 'name': 'Cached Item 2'}];
    } catch (e) {
      print('Error parsing JSON list: $e');
      return [];
    }
  }
  
  Map<String, dynamic> _parseJson(String jsonString) {
    // This is a simplified implementation
    // In a real app, you would use a proper JSON parser
    try {
      // For demo purposes only
      return {'id': 'cached-doc', 'name': 'Cached Document'};
    } catch (e) {
      print('Error parsing JSON: $e');
      return {};
    }
  }
}