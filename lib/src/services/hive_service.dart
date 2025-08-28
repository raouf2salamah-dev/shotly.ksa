import 'package:hive_flutter/hive_flutter.dart';
import '../models/cache_item.dart';

class HiveService {
  static const String cacheBoxName = 'cache_box';
  
  // Initialize Hive boxes
  static Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CacheItemAdapter());
    }
    
    // Open boxes
    await Hive.openBox<CacheItem>(cacheBoxName);
    print('Hive boxes opened successfully!');
  }
  
  // Get cache box
  static Box<CacheItem> getCacheBox() {
    return Hive.box<CacheItem>(cacheBoxName);
  }
  
  // Save item to cache
  static Future<void> saveToCache(String key, String value) async {
    final box = getCacheBox();
    final cacheItem = CacheItem.create(key: key, value: value);
    await box.put(cacheItem.id, cacheItem);
  }
  
  // Get item from cache by key
  static Future<String?> getFromCache(String key) async {
    final box = getCacheBox();
    final items = box.values.where((item) => item.key == key).toList();
    
    if (items.isEmpty) {
      return null;
    }
    
    // Sort by timestamp (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.first.value;
  }
  
  // Get cache item object by key
  static Future<CacheItem?> getCacheItem(String key) async {
    final box = getCacheBox();
    final items = box.values.where((item) => item.key == key).toList();
    
    if (items.isEmpty) {
      return null;
    }
    
    // Sort by timestamp (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.first;
  }
  
  // Delete item from cache by key
  static Future<void> deleteFromCache(String key) async {
    final box = getCacheBox();
    final itemsToDelete = box.values.where((item) => item.key == key).toList();
    
    for (var item in itemsToDelete) {
      await box.delete(item.key);
    }
  }
  
  // Clear all cache
  static Future<void> clearCache() async {
    final box = getCacheBox();
    await box.clear();
  }
  
  // Get all cache items
  static List<CacheItem> getAllCacheItems() {
    final box = getCacheBox();
    return box.values.toList();
  }
  
  // Close Hive boxes
  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}