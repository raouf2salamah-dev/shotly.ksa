import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// SecureStorageService provides encrypted storage for sensitive data
/// using platform-specific security features (Keychain on iOS, EncryptedSharedPreferences on Android)
class SecureStorageService {
  static final _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  /// Store a string value securely
  /// 
  /// [key] - The key to store the value under
  /// [value] - The string value to store
  static Future<void> write(String key, String value) => 
      _store.write(key: key, value: value);
  
  /// Read a string value from secure storage
  /// 
  /// [key] - The key to retrieve
  /// Returns the stored string or null if not found
  static Future<String?> read(String key) => _store.read(key: key);
  
  /// Delete a value from secure storage
  /// 
  /// [key] - The key to delete
  static Future<void> delete(String key) => _store.delete(key: key);
}