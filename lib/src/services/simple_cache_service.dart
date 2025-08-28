import 'package:hive/hive.dart'; 
 
class SimpleCacheService { 
  static const _boxName = 'simple_cache'; 
  static const _cacheDuration = Duration(hours: 24); // global expiration 
 
  final int maxItems; // max number of cache entries 
  late Box _cacheBox; 
 
  SimpleCacheService({this.maxItems = 100}); // default limit 100 items 
 
  Future<void> init() async { 
    _cacheBox = await Hive.openBox(_boxName); 
  } 
 
  /// Save data with automatic expiration and size control 
  Future<void> save(String key, dynamic data) async { 
    final timestamp = DateTime.now().millisecondsSinceEpoch; 
 
    // Save entry 
    await _cacheBox.put(key, { 
      'data': data, 
      'timestamp': timestamp, 
    }); 
 
    // Purge expired first 
    _purgeExpired(); 
 
    // Purge old items if over limit 
    if (_cacheBox.length > maxItems) { 
      _purgeOldest(); 
    } 
  } 
 
  /// Retrieve data if not expired 
  T? get<T>(String key) { 
    final entry = _cacheBox.get(key); 
    if (entry == null) return null; 
 
    final savedTime = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']); 
    if (DateTime.now().difference(savedTime) > _cacheDuration) { 
      _cacheBox.delete(key); // remove expired 
      return null; 
    } 
 
    return entry['data'] as T; 
  } 
 
  /// Delete a single entry 
  Future<void> delete(String key) async => _cacheBox.delete(key); 
 
  /// Clear the entire cache 
  Future<void> clear() async => _cacheBox.clear(); 
 
  /// Remove expired items 
  void _purgeExpired() { 
    final now = DateTime.now(); 
    final keysToRemove = <String>[]; 
 
    _cacheBox.toMap().forEach((key, value) { 
      final savedTime = DateTime.fromMillisecondsSinceEpoch(value['timestamp']); 
      if (now.difference(savedTime) > _cacheDuration) { 
        keysToRemove.add(key as String); 
      } 
    }); 
 
    for (var key in keysToRemove) { 
      _cacheBox.delete(key); 
    } 
  } 
 
  /// Remove oldest items if over maxItems limit 
  void _purgeOldest() { 
    final entries = _cacheBox.toMap().entries.toList(); 
 
    // Sort by timestamp ascending (oldest first) 
    entries.sort((a, b) => 
        (a.value['timestamp'] as int).compareTo(b.value['timestamp'] as int)); 
 
    final itemsToRemove = entries.length - maxItems; 
    for (int i = 0; i < itemsToRemove; i++) { 
      _cacheBox.delete(entries[i].key); 
    } 
  } 
}