import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../bootstrap/security_bootstrap.dart';

/// BuildMetadataService is responsible for fetching and parsing build metadata
/// from the CI/CD pipeline.
class BuildMetadataService {
  static final BuildMetadataService _instance = BuildMetadataService._internal();
  
  /// Singleton instance
  factory BuildMetadataService() => _instance;
  
  BuildMetadataService._internal();
  
  /// The base URL for the CI/CD API
  String? _cicdApiBaseUrl;
  
  /// The API token for authentication
  String? _apiToken;
  
  /// Dio instance with certificate pinning
  late final Dio _dio;
  
  /// Initialize the service with the CI/CD API URL and token
  void initialize({required String cicdApiBaseUrl, required String apiToken}) {
    _cicdApiBaseUrl = cicdApiBaseUrl;
    _apiToken = apiToken;
    
    // Initialize Dio with certificate pinning
    _dio = SecurityBootstrap.buildPinnedDio();
    _dio.options.baseUrl = _cicdApiBaseUrl!;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }
  
  /// Check if the service is initialized
  bool get isInitialized => _cicdApiBaseUrl != null && _apiToken != null;
  
  /// Fetch the latest build metadata
  Future<Map<String, dynamic>> fetchLatestBuildMetadata() async {
    if (!isInitialized) {
      return _getMockBuildMetadata();
    }
    
    try {
      final response = await _dio.get(
        '/builds/latest',
        options: Options(headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        }),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Error fetching build metadata: ${response.statusCode}');
        return _getMockBuildMetadata();
      }
    } catch (e) {
      debugPrint('Exception fetching build metadata: $e');
      return _getMockBuildMetadata();
    }
  }
  
  /// Fetch build history
  Future<List<Map<String, dynamic>>> fetchBuildHistory({int limit = 10}) async {
    if (!isInitialized) {
      return _getMockBuildHistory(limit);
    }
    
    try {
      final response = await _dio.get(
        '/builds',
        queryParameters: {'limit': limit},
        options: Options(headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        }),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        debugPrint('Error fetching build history: ${response.statusCode}');
        return _getMockBuildHistory(limit);
      }
    } catch (e) {
      debugPrint('Exception fetching build history: $e');
      return _getMockBuildHistory(limit);
    }
  }
  
  /// Fetch test results for a specific build
  Future<Map<String, dynamic>> fetchTestResults(String buildId) async {
    if (!isInitialized) {
      return _getMockTestResults();
    }
    
    try {
      final response = await _dio.get(
        '/builds/$buildId/tests',
        options: Options(headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        }),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Error fetching test results: ${response.statusCode}');
        return _getMockTestResults();
      }
    } catch (e) {
      debugPrint('Exception fetching test results: $e');
      return _getMockTestResults();
    }
  }
  
  /// Get mock build metadata for development/demo purposes
  Map<String, dynamic> _getMockBuildMetadata() {
    return {
      'buildNumber': '42',
      'buildDate': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      'branch': 'main',
      'commitHash': '8f4d76a',
      'buildStatus': 'success',
      'duration': '12m 34s',
      'triggeredBy': 'GitHub Actions',
    };
  }
  
  /// Get mock build history for development/demo purposes
  List<Map<String, dynamic>> _getMockBuildHistory(int limit) {
    final List<Map<String, dynamic>> history = [];
    
    for (int i = 0; i < limit; i++) {
      final buildNumber = 42 - i;
      final daysAgo = i;
      final passed = 118 - (i % 5);
      final total = 120;
      final failed = total - passed;
      
      history.add({
        'buildNumber': buildNumber.toString(),
        'buildDate': DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String(),
        'branch': i % 3 == 0 ? 'develop' : 'main',
        'commitHash': '8f4d76${String.fromCharCode(97 + i)}',
        'buildStatus': failed == 0 ? 'success' : (failed < 3 ? 'partial_success' : 'failure'),
        'duration': '${10 + (i % 5)}m ${20 + (i % 40)}s',
        'triggeredBy': i % 2 == 0 ? 'GitHub Actions' : 'Manual',
        'tests': {
          'total': total,
          'passed': passed,
          'failed': failed,
        },
      });
    }
    
    return history;
  }
  
  /// Get mock test results for development/demo purposes
  Map<String, dynamic> _getMockTestResults() {
    return {
      'total': 120,
      'passed': 118,
      'failed': 2,
      'skipped': 0,
      'duration': '45.2s',
      'coverage': '87.3%',
      'failedTests': [
        {
          'name': 'testSSLPinningWithInvalidCertificate',
          'file': 'test/security/ssl_pinning_test.dart',
          'message': 'Expected certificate validation to fail',
        },
        {
          'name': 'testSecureStorageOnEmulator',
          'file': 'test/security/secure_storage_test.dart',
          'message': 'Failed to initialize secure storage on emulator',
        },
      ],
    };
  }
}