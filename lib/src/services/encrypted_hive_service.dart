import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

/// EncryptedHiveService provides encrypted storage using Hive with AES-256 encryption
/// The encryption key is securely stored using SecureStorageService
class EncryptedHiveService {
  static final EncryptedHiveService _instance = EncryptedHiveService._internal();
  static const String _secureStorageKey = 'hive_encryption_key';
  static const String _encryptedBoxName = 'encrypted_box';
  
  Box? _encryptedBox;
  bool _isInitialized = false;
  
  // Singleton pattern
  factory EncryptedHiveService() {
    return _instance;
  }
  
  EncryptedHiveService._internal();
  
  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Static getter to check if the service is initialized
  static bool get initialized => _instance._isInitialized;
  
  /// Static getter to access the encrypted box
  static Box? get box => _instance._encryptedBox;
  
  /// Initialize encrypted Hive
  /// Must be called before using any other methods
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Get or generate encryption key
      final encryptionKey = await _getEncryptionKey();
      
      // Open encrypted box
      _encryptedBox = await Hive.openBox(
        _encryptedBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      
      _isInitialized = true;
      debugPrint('🔒 Encrypted Hive box opened successfully!');
    } catch (e) {
      debugPrint('❌ Error initializing encrypted Hive: $e');
      // If there's an error with the encryption key, we might need to reset it
      if (e.toString().contains('Encryption key invalid')) {
        await _resetEncryptionKey();
        throw Exception('Encryption key was invalid and has been reset. Please try again.');
      } else {
        rethrow;
      }
    }
  }
  
  /// Static method to initialize encrypted Hive during app bootstrap
  /// This can be called directly in main.dart for early initialization
  static Future<EncryptedHiveService> initEarly() async {
    final instance = EncryptedHiveService();
    await instance.init();
    return instance;
  }
  
  /// Get encryption key from secure storage or generate a new one
  Future<List<int>> _getEncryptionKey() async {
    // Try to retrieve existing key
    String? keyString = await SecureStorageService.read(_secureStorageKey);
    
    if (keyString == null) {
      // Generate a new key (32 bytes for AES-256)
      final key = Hive.generateSecureKey();
      
      // Store the key in secure storage
      await SecureStorageService.write(
        _secureStorageKey,
        base64Url.encode(key),
      );
      
      debugPrint('🔑 Generated new encryption key');
      return key;
    } else {
      // Decode existing key
      debugPrint('🔑 Using existing encryption key');
      return base64Url.decode(keyString);
    }
  }
  
  /// Reset the encryption key (use with caution - all encrypted data will be lost)
  Future<void> _resetEncryptionKey() async {
    await SecureStorageService.delete(_secureStorageKey);
    if (_encryptedBox != null && _encryptedBox!.isOpen) {
      await _encryptedBox!.close();
    }
    _isInitialized = false;
    debugPrint('🔄 Encryption key has been reset');
  }
  
  /// Save data to encrypted box
  /// 
  /// [key] - The key to store the value under
  /// [value] - The value to store (must be JSON serializable)
  Future<void> saveData(String key, dynamic value) async {
    _checkInitialized();
    await _encryptedBox!.put(key, value);
  }
  
  /// Static method to save data to encrypted box
  /// 
  /// [key] - The key to store the value under
  /// [value] - The value to store (must be JSON serializable)
  static Future<void> save(String key, dynamic value) async {
    if (!initialized) throw Exception('EncryptedHiveService not initialized. Call initEarly() first.');
    await _instance._encryptedBox!.put(key, value);
  }
  
  /// Get data from encrypted box
  /// 
  /// [key] - The key to retrieve
  /// Returns the stored value or null if not found
  dynamic getData(String key) {
    _checkInitialized();
    return _encryptedBox!.get(key);
  }
  
  /// Static method to get data from encrypted box
  /// 
  /// [key] - The key to retrieve
  /// Returns the stored value or null if not found
  static dynamic get(String key) {
    if (!initialized) throw Exception('EncryptedHiveService not initialized. Call initEarly() first.');
    return _instance._encryptedBox!.get(key);
  }
  
  /// Check if a key exists in encrypted box
  /// 
  /// [key] - The key to check
  /// Returns true if the key exists
  bool containsKey(String key) {
    _checkInitialized();
    return _encryptedBox!.containsKey(key);
  }
  
  /// Static method to check if a key exists in encrypted box
  /// 
  /// [key] - The key to check
  /// Returns true if the key exists
  static bool contains(String key) {
    if (!initialized) throw Exception('EncryptedHiveService not initialized. Call initEarly() first.');
    return _instance._encryptedBox!.containsKey(key);
  }
  
  /// Delete data from encrypted box
  /// 
  /// [key] - The key to delete
  Future<void> deleteData(String key) async {
    _checkInitialized();
    await _encryptedBox!.delete(key);
  }
  
  /// Static method to delete data from encrypted box
  /// 
  /// [key] - The key to delete
  static Future<void> delete(String key) async {
    if (!initialized) throw Exception('EncryptedHiveService not initialized. Call initEarly() first.');
    await _instance._encryptedBox!.delete(key);
  }
  
  /// Clear all data from encrypted box
  Future<void> clearAll() async {
    _checkInitialized();
    await _encryptedBox!.clear();
  }
  
  /// Static method to clear all data from encrypted box
  static Future<void> clear() async {
    if (!initialized) throw Exception('EncryptedHiveService not initialized. Call initEarly() first.');
    await _instance._encryptedBox!.clear();
  }
  
  /// Get all keys in encrypted box
  List<dynamic> getAllKeys() {
    _checkInitialized();
    return _encryptedBox!.keys.toList();
  }
  
  /// Static method to get all keys in encrypted box
  static List<dynamic> keys() {
    if (!initialized) throw Exception('EncryptedHiveService not initialized. Call initEarly() first.');
    return _instance._encryptedBox!.keys.toList();
  }
  
  /// Get all values in encrypted box
  List<dynamic> getAllValues() {
    _checkInitialized();
    return _encryptedBox!.values.toList();
  }
  
  /// Static method to get all values in encrypted box
  static List<dynamic> values() {
    if (!initialized) throw Exception('EncryptedHiveService not initialized. Call initEarly() first.');
    return _instance._encryptedBox!.values.toList();
  }
  
  /// Close encrypted box
  Future<void> close() async {
    if (_encryptedBox != null && _encryptedBox!.isOpen) {
      await _encryptedBox!.close();
      _isInitialized = false;
      debugPrint('🔒 Encrypted Hive box closed');
    }
  }
  
  /// Static method to close encrypted box
  static Future<void> closeBox() async {
    if (_instance._encryptedBox != null && _instance._encryptedBox!.isOpen) {
      await _instance._encryptedBox!.close();
      _instance._isInitialized = false;
      debugPrint('🔒 Encrypted Hive box closed');
    }
  }
  
  /// Check if the service is initialized
  void _checkInitialized() {
    if (!_isInitialized || _encryptedBox == null || !_encryptedBox!.isOpen) {
      throw Exception('EncryptedHiveService not initialized. Call init() first.');
    }
  }
}