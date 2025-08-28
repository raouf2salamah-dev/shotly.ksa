import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/document.dart';
import 'hive_service.dart';

class BundleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _bundlePrefix = 'bundle_';
  
  /// Downloads a Firestore bundle for a specific collection and stores it locally
  Future<void> downloadBundle(String collection) async {
    try {
      // Create a bundle of the collection data
      final snapshot = await _firestore.collection(collection).get();
      final documents = snapshot.docs.map((doc) => Document(
        id: doc.id,
        data: doc.data(),
        collection: collection,
        updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      )).toList();
      
      // Convert to JSON and store in Hive
      final bundleData = jsonEncode(documents.map((doc) => doc.toJson()).toList());
      await HiveService.saveToCache('$_bundlePrefix$collection', bundleData);
      
      debugPrint('📦 Bundle downloaded and stored for collection: $collection');
    } catch (e) {
      debugPrint('❌ Error downloading bundle: $e');
      rethrow;
    }
  }
  
  /// Reads bundle data from local storage
  Future<List<Document>> readBundleData(String collection) async {
    try {
      final bundleData = await HiveService.getFromCache('$_bundlePrefix$collection');
      
      if (bundleData == null) {
        debugPrint('⚠️ No bundle data found for collection: $collection');
        return [];
      }
      
      final List<dynamic> decodedData = jsonDecode(bundleData);
      final documents = decodedData.map((item) => Document.fromJson(item)).toList();
      
      debugPrint('📂 Retrieved ${documents.length} documents from bundle: $collection');
      return documents;
    } catch (e) {
      debugPrint('❌ Error reading bundle data: $e');
      return [];
    }
  }
  
  /// Checks if a bundle exists and is not expired
  Future<bool> isBundleValid(String collection, {Duration maxAge = const Duration(days: 1)}) async {
    try {
      final cacheItem = await HiveService.getCacheItem('$_bundlePrefix$collection');
      
      if (cacheItem == null) {
        return false;
      }
      
      final DateTime timestamp = cacheItem.timestamp;
      final DateTime now = DateTime.now();
      final bool isValid = now.difference(timestamp) < maxAge;
      
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking bundle validity: $e');
      return false;
    }
  }
  
  /// Clears a specific bundle from storage
  Future<void> clearBundle(String collection) async {
    await HiveService.deleteFromCache('$_bundlePrefix$collection');
    debugPrint('🧹 Cleared bundle for collection: $collection');
  }
  
  /// Clears all bundles from storage
  Future<void> clearAllBundles() async {
    final box = HiveService.getCacheBox();
    final bundleKeys = box.values
        .where((item) => item.key.startsWith(_bundlePrefix))
        .map((item) => item.key)
        .toList();
    
    for (final key in bundleKeys) {
      await HiveService.deleteFromCache(key);
    }
    
    debugPrint('🧹 Cleared all bundles (${bundleKeys.length} total)');
  }
}