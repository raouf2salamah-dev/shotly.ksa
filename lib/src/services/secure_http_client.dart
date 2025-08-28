import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';
import '../../../bootstrap/security_bootstrap.dart';

// Certificate validation is now handled by CertificatePinningService

/// SecureHttpClient implements certificate pinning for secure API communication
/// 
/// This class now uses the centralized CertificatePinningService for certificate validation
/// 
/// Important considerations:
/// 1. Certificate Rotation: Handled by CertificatePinningService
/// 2. Multiple Environments: Configured in CertificatePinningService
/// 3. Backup Mechanism: Implemented in CertificatePinningService
/// 4. User Experience: Error handling provided by CertificatePinningService
class SecureHttpClient {
  
  /// Get the Dio instance with certificate pinning from SecurityBootstrap
  /// 
  /// This is a wrapper around SecurityBootstrap.dio to maintain backward compatibility
  static Dio get dio {
    // Use the SecurityBootstrap.dio instance which already has certificate pinning configured
    return SecurityBootstrap.dio;
  }
  
  /// Test the certificate pinning implementation
  /// 
  /// This method can be used to verify that certificate pinning is working correctly.
  /// It attempts to make a request to the specified URL and returns information about
  /// whether the certificate validation succeeded or failed.
  /// 
  /// Usage:
  /// ```dart
  /// final testResult = await SecureHttpClient.testCertificatePinning('https://api.yourdomain.com');
  /// print(testResult);
  /// ```
  static Future<Map<String, dynamic>> testCertificatePinning(String url) async {
    // Use the centralized certificate pinning service for testing
    return SecurityBootstrap.testCertificatePinning(url);
  }
  
  /// Set the environment for certificate validation
  /// 
  /// This allows switching between different sets of certificate fingerprints
  /// for different environments (production, staging, development)
  static void setEnvironment(String environment) {
    // Use the centralized certificate pinning service for environment setting
    SecurityBootstrap.certificatePinningService.setEnvironment(environment);
  }
  
  /// Enable verbose logging for debugging certificate pinning
  static void setVerboseLogging(bool enabled) {
    // Use the centralized certificate pinning service for verbose logging
    SecurityBootstrap.certificatePinningService.enableVerboseLogging = enabled;
  }
  
  /// Set a callback for certificate validation failures
  static void setValidationFailureCallback(Function(String host, String fingerprint) callback) {
    SecurityBootstrap.certificatePinningService.onCertificateValidationFailure = callback;
  }
}