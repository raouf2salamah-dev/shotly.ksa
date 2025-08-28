import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

/// TokenService handles secure storage and management of authentication tokens
/// including access tokens (short-lived) and refresh tokens (longer-lived)
class TokenService {
  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';
  
  // Default expiration times
  static const Duration defaultAccessTokenExpiry = Duration(minutes: 15);
  static const Duration defaultRefreshTokenExpiry = Duration(days: 7);
  
  /// Store access token with expiration
  /// 
  /// [token] - The access token to store
  /// [expiresIn] - Optional duration until token expires (defaults to 15 minutes)
  static Future<void> storeAccessToken(String token, {Duration? expiresIn}) async {
    final expiry = DateTime.now().add(expiresIn ?? defaultAccessTokenExpiry);
    
    // Store the token
    await SecureStorageService.write(_accessTokenKey, token);
    
    // Store the expiration timestamp
    await SecureStorageService.write(
      _accessTokenExpiryKey,
      expiry.millisecondsSinceEpoch.toString(),
    );
    
    debugPrint('🔑 Access token stored, expires: ${expiry.toIso8601String()}');
  }
  
  /// Store refresh token with expiration
  /// 
  /// [token] - The refresh token to store
  /// [expiresIn] - Optional duration until token expires (defaults to 7 days)
  static Future<void> storeRefreshToken(String token, {Duration? expiresIn}) async {
    final expiry = DateTime.now().add(expiresIn ?? defaultRefreshTokenExpiry);
    
    // Store the token
    await SecureStorageService.write(_refreshTokenKey, token);
    
    // Store the expiration timestamp
    await SecureStorageService.write(
      _refreshTokenExpiryKey,
      expiry.millisecondsSinceEpoch.toString(),
    );
    
    debugPrint('🔑 Refresh token stored, expires: ${expiry.toIso8601String()}');
  }
  
  /// Get access token if not expired
  /// 
  /// Returns the access token or null if expired or not found
  static Future<String?> getAccessToken() async {
    final token = await SecureStorageService.read(_accessTokenKey);
    final expiryStr = await SecureStorageService.read(_accessTokenExpiryKey);
    
    if (token == null || expiryStr == null) return null;
    
    // Check if token is expired
    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    if (DateTime.now().isAfter(expiry)) {
      debugPrint('⚠️ Access token expired');
      return null;
    }
    
    return token;
  }
  
  /// Get refresh token if not expired
  /// 
  /// Returns the refresh token or null if expired or not found
  static Future<String?> getRefreshToken() async {
    final token = await SecureStorageService.read(_refreshTokenKey);
    final expiryStr = await SecureStorageService.read(_refreshTokenExpiryKey);
    
    if (token == null || expiryStr == null) return null;
    
    // Check if token is expired
    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    if (DateTime.now().isAfter(expiry)) {
      debugPrint('⚠️ Refresh token expired');
      return null;
    }
    
    return token;
  }
  
  /// Check if access token is valid (exists and not expired)
  static Future<bool> hasValidAccessToken() async {
    return await getAccessToken() != null;
  }
  
  /// Check if refresh token is valid (exists and not expired)
  static Future<bool> hasValidRefreshToken() async {
    return await getRefreshToken() != null;
  }
  
  /// Clear all tokens
  static Future<void> clearTokens() async {
    await SecureStorageService.delete(_accessTokenKey);
    await SecureStorageService.delete(_refreshTokenKey);
    await SecureStorageService.delete(_accessTokenExpiryKey);
    await SecureStorageService.delete(_refreshTokenExpiryKey);
    debugPrint('🧹 All tokens cleared');
  }
  
  /// Get time remaining until access token expires
  /// 
  /// Returns the duration until expiry or null if token doesn't exist
  static Future<Duration?> getAccessTokenTimeRemaining() async {
    final expiryStr = await SecureStorageService.read(_accessTokenExpiryKey);
    if (expiryStr == null) return null;
    
    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    final now = DateTime.now();
    
    if (now.isAfter(expiry)) return Duration.zero;
    return expiry.difference(now);
  }
  
  /// Get time remaining until refresh token expires
  /// 
  /// Returns the duration until expiry or null if token doesn't exist
  static Future<Duration?> getRefreshTokenTimeRemaining() async {
    final expiryStr = await SecureStorageService.read(_refreshTokenExpiryKey);
    if (expiryStr == null) return null;
    
    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    final now = DateTime.now();
    
    if (now.isAfter(expiry)) return Duration.zero;
    return expiry.difference(now);
  }
}