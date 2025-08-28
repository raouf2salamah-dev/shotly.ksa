import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// SecureStorage provides encrypted storage for sensitive data
/// using platform-specific security features (Keychain on iOS, EncryptedSharedPreferences on Android)
/// 
/// SECURITY WARNING: While this service uses platform-specific secure storage mechanisms,
/// client-side secrets (including signing keys) may still be extractable on rooted/jailbroken
/// devices or through sophisticated attacks. Never rely solely on client-side security for
/// protecting highly sensitive information.
class SecureStorage {
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
  
  /// Delete all values from secure storage
  static Future<void> deleteAll() => _store.deleteAll();
  
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
  
  /// Store authentication tokens securely
  /// 
  /// [accessToken] - The access token to store
  /// [refreshToken] - The refresh token to store
  static Future<void> storeAuthTokens(String accessToken, String refreshToken) async {
    await write('access_token', accessToken);
    await write('refresh_token', refreshToken);
    await write('token_timestamp', DateTime.now().millisecondsSinceEpoch.toString());
  }
  
  /// Retrieve the access token
  /// 
  /// Returns the stored access token or null if not found
  static Future<String?> getAccessToken() => read('access_token');
  
  /// Retrieve the refresh token
  /// 
  /// Returns the stored refresh token or null if not found
  static Future<String?> getRefreshToken() => read('refresh_token');
  
  /// Clear authentication tokens
  static Future<void> clearAuthTokens() async {
    await delete('access_token');
    await delete('refresh_token');
    await delete('token_timestamp');
  }
  
  /// Generate an HMAC-SHA256 signature for an API request
  /// 
  /// [path] - The request path
  /// [body] - The request body
  /// [timestamp] - The request timestamp
  /// Returns the signature or null if no signing key is available
  static Future<String?> signRequest(String path, String body, String timestamp) async {
    final key = await getDeviceSigningKey();
    if (key == null) return null;
    
    final dataToSign = '$path|$body|$timestamp';
    final hmacSha256 = Hmac(sha256, utf8.encode(key));
    final digest = hmacSha256.convert(utf8.encode(dataToSign));
    return base64.encode(digest.bytes);
  }
  
  /// Store user preferences securely
  /// 
  /// [preferences] - Map of preference key/values to store
  static Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    final jsonString = jsonEncode(preferences);
    await write('user_preferences', jsonString);
  }
  
  /// Retrieve user preferences
  /// 
  /// Returns the stored preferences as a Map or empty Map if not found
  static Future<Map<String, dynamic>> getUserPreferences() async {
    final jsonString = await read('user_preferences');
    if (jsonString == null) return {};
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}