import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../bootstrap/security_bootstrap.dart';

/// SecurityFeaturesService is responsible for checking and reporting on
/// which security features are currently active in the application.
class SecurityFeaturesService {
  static final SecurityFeaturesService _instance = SecurityFeaturesService._internal();
  
  /// Singleton instance
  factory SecurityFeaturesService() => _instance;
  
  SecurityFeaturesService._internal();
  
  /// The base URL for the security API
  String? _securityApiBaseUrl;
  
  /// The API token for authentication
  String? _apiToken;
  
  /// Dio instance with certificate pinning
  late final Dio _dio;
  
  /// Initialize the service with the security API URL and token
  void initialize({required String securityApiBaseUrl, required String apiToken}) {
    _securityApiBaseUrl = securityApiBaseUrl;
    _apiToken = apiToken;
    
    // Initialize Dio with certificate pinning
    _dio = SecurityBootstrap.buildPinnedDio();
    _dio.options.baseUrl = _securityApiBaseUrl!;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }
  
  /// Check if the service is initialized
  bool get isInitialized => _securityApiBaseUrl != null && _apiToken != null;
  
  /// Fetch the status of all security features
  Future<Map<String, bool>> fetchSecurityFeatures() async {
    if (!isInitialized) {
      return _getMockSecurityFeatures();
    }
    
    try {
      final response = await _dio.get(
        '/security/features',
        options: Options(headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, value as bool));
      } else {
        debugPrint('Error fetching security features: ${response.statusCode}');
        return _getMockSecurityFeatures();
      }
    } catch (e) {
      debugPrint('Exception fetching security features: $e');
      return _getMockSecurityFeatures();
    }
  }
  
  /// Fetch detailed information about a specific security feature
  Future<Map<String, dynamic>> fetchFeatureDetails(String featureName) async {
    if (!isInitialized) {
      return _getMockFeatureDetails(featureName);
    }
    
    try {
      final response = await _dio.get(
        '/security/features/$featureName',
        options: Options(headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        }),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Error fetching feature details: ${response.statusCode}');
        return _getMockFeatureDetails(featureName);
      }
    } catch (e) {
      debugPrint('Exception fetching feature details: $e');
      return _getMockFeatureDetails(featureName);
    }
  }
  
  /// Get mock security features for development/demo purposes
  Map<String, bool> _getMockSecurityFeatures() {
    return {
      'SSL Pinning': true,
      'Jailbreak Detection': true,
      'Secure Storage': true,
      'App Obfuscation': true,
      'Biometric Authentication': false,
      'Screenshot Prevention': true,
    };
  }
  
  /// Get mock feature details for development/demo purposes
  Map<String, dynamic> _getMockFeatureDetails(String featureName) {
    final Map<String, Map<String, dynamic>> details = {
      'SSL Pinning': {
        'enabled': true,
        'description': 'Prevents man-in-the-middle attacks by validating server certificates',
        'implementation': 'CertificatePinningService class with SHA-256 certificate fingerprint validation',
        'domains': ['api.example.com', 'api.yourdomain.com'],
        'lastUpdated': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      'Jailbreak Detection': {
        'enabled': true,
        'description': 'Detects if a device is jailbroken/rooted or has developer mode enabled',
        'implementation': 'DeviceIntegrity class using flutter_jailbreak_detection',
        'lastUpdated': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      },
      'Secure Storage': {
        'enabled': true,
        'description': 'Provides encrypted storage for sensitive data',
        'implementation': 'SecureStorage class using flutter_secure_storage',
        'lastUpdated': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
      'App Obfuscation': {
        'enabled': true,
        'description': 'Makes reverse engineering harder by obfuscating code',
        'implementation': 'Flutter build with --obfuscate flag',
        'lastUpdated': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      },
      'Biometric Authentication': {
        'enabled': false,
        'description': 'Adds an extra layer of security for accessing sensitive data',
        'implementation': 'Not implemented yet',
        'lastUpdated': null,
      },
      'Screenshot Prevention': {
        'enabled': true,
        'description': 'Prevents screenshots of sensitive screens',
        'implementation': 'FLAG_SECURE on Android, custom overlay on iOS',
        'lastUpdated': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
    };
    
    return details[featureName] ?? {
      'enabled': false,
      'description': 'Unknown feature',
      'implementation': 'Not implemented',
      'lastUpdated': null,
    };
  }
}