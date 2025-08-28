import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../security/secure_storage.dart';
import 'package:flutter/foundation.dart';

/// RequestSigner provides HMAC-SHA256 request signing functionality
/// for secure client-server communication.
/// 
/// This helps prevent request tampering and replay attacks by signing
/// requests with a device-specific key and including a timestamp.
class RequestSigner {
  /// Generate an HMAC-SHA256 signature for an API request
  /// 
  /// [path] - The request path
  /// [body] - The request body (can be empty for GET requests)
  /// [timestamp] - The request timestamp in milliseconds since epoch
  /// [apiKey] - Optional API key to use instead of the stored device signing key
  /// 
  /// Returns the signature as a base64-encoded string, or null if signing fails
  static Future<String?> signRequest({
    required String path,
    String body = '',
    String? timestamp,
    String? apiKey,
  }) async {
    // Use provided timestamp or generate a new one
    final requestTimestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    try {
      // Use provided API key or get the stored device signing key
      final key = apiKey ?? await SecureStorage.getDeviceSigningKey();
      if (key == null) {
        debugPrint('No signing key available');
        return null;
      }
      
      // Concatenate the data to sign
      final dataToSign = '$path|$body|$requestTimestamp';
      
      // Create HMAC-SHA256 signature
      final hmacSha256 = Hmac(sha256, utf8.encode(key));
      final digest = hmacSha256.convert(utf8.encode(dataToSign));
      
      // Return base64-encoded signature
      return base64.encode(digest.bytes);
    } catch (e) {
      debugPrint('Error signing request: $e');
      return null;
    }
  }
  
  /// Verify an HMAC-SHA256 signature for an API request
  /// 
  /// This is primarily for testing purposes, as verification is typically done server-side
  /// 
  /// [path] - The request path
  /// [body] - The request body
  /// [timestamp] - The request timestamp
  /// [signature] - The signature to verify
  /// [apiKey] - The API key used for signing
  /// 
  /// Returns true if the signature is valid
  static bool verifySignature({
    required String path,
    required String body,
    required String timestamp,
    required String signature,
    required String apiKey,
  }) {
    try {
      // Concatenate the data that was signed
      final dataToSign = '$path|$body|$timestamp';
      
      // Create HMAC-SHA256 signature
      final hmacSha256 = Hmac(sha256, utf8.encode(apiKey));
      final digest = hmacSha256.convert(utf8.encode(dataToSign));
      final expectedSignature = base64.encode(digest.bytes);
      
      // Compare the expected signature with the provided signature
      return expectedSignature == signature;
    } catch (e) {
      debugPrint('Error verifying signature: $e');
      return false;
    }
  }
  
  /// Check if a timestamp is within the allowed time window
  /// 
  /// This helps prevent replay attacks by rejecting requests with old timestamps
  /// 
  /// [timestamp] - The timestamp to check (milliseconds since epoch)
  /// [maxAgeMinutes] - The maximum age of the timestamp in minutes
  /// 
  /// Returns true if the timestamp is valid
  static bool isTimestampValid(String timestamp, {int maxAgeMinutes = 5}) {
    try {
      final requestTime = int.parse(timestamp);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final maxAgeMillis = maxAgeMinutes * 60 * 1000;
      
      // Check if the timestamp is not too old and not in the future
      return (currentTime - requestTime <= maxAgeMillis) && (requestTime <= currentTime);
    } catch (e) {
      debugPrint('Error validating timestamp: $e');
      return false;
    }
  }
}