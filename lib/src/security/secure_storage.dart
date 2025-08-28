import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// SecureStorageService provides encrypted storage for sensitive data
/// using platform-specific security features (Keychain on iOS, EncryptedSharedPreferences on Android)
/// 
/// SECURITY WARNING: While this service uses platform-specific secure storage mechanisms,
/// client-side secrets (including signing keys) may still be extractable on rooted/jailbroken
/// devices or through sophisticated attacks. Never rely solely on client-side security for
/// protecting highly sensitive information.
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
  
  /// Store a device signing key securely
  /// This key should be created server-side during device registration
  /// 
  /// [signingKey] - The signing key to store
  static Future<void> storeDeviceSigningKey(String signingKey) => 
      write('device_signing_key', signingKey);
      
  /// Retrieve the device signing key
  /// 
  /// Returns the stored signing key or null if not found
  static Future<String?> getDeviceSigningKey() => read('device_signing_key');
  
  /// Generate an HMAC-SHA256 signature for an API request
  /// 
  /// [path] - The API endpoint path
  /// [body] - The request body (can be empty string for GET requests)
  /// [timestamp] - Current timestamp in milliseconds since epoch
  /// Returns the base64-encoded signature or null if signing key is not available
  static Future<String?> signRequest(String path, String body, String timestamp) async {
    final signingKey = await getDeviceSigningKey();
    if (signingKey == null) return null;
    
    // Use the optimized signing method with pipe delimiter for better security
    return signRequest_internal(signingKey, path, body, timestamp);
  }
  
  /// Internal implementation of the signing algorithm
  /// Uses pipe delimiter between components for better security
  static String signRequest_internal(String secret, String path, String body, String ts) {
    final payload = utf8.encode('$path|$body|$ts');
    final h = Hmac(sha256, utf8.encode(secret));
    return base64Encode(h.convert(payload).bytes);
  }
}