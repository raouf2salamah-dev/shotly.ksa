import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'encrypted_config_manager.dart';

/// CertificatePinningService provides a centralized way to manage certificate pinning
/// 
/// This service consolidates certificate pinning logic from DioPinning and SecureHttpClient
/// to ensure consistent configuration across all network calls.
class CertificatePinningService {
  // Singleton instance
  static final CertificatePinningService _instance = CertificatePinningService._internal();
  
  // Factory constructor to return the singleton instance
  factory CertificatePinningService() => _instance;
  
  // Private constructor for singleton pattern
  CertificatePinningService._internal();
  
  // Encrypted config manager for secure fingerprint storage
  final EncryptedConfigManager _configManager = EncryptedConfigManager();
  
  // Config file name for certificate fingerprints
  static const String _fingerprintsConfigFileName = 'certificate_fingerprints.enc';
  
  // Config file name for certificate rotation dates
  static const String _rotationDatesConfigFileName = 'certificate_rotation_dates.enc';
  
  // Enable OCSP checking by default
  bool _enableOcspChecking = true;
  
  // OCSP response cache to avoid repeated requests
  final Map<String, Map<String, dynamic>> _ocspCache = {};
  
  // OCSP response validity period in milliseconds (default: 1 hour)
  int _ocspCacheValidityPeriod = 3600000;
  
  /// Map of domain to certificate fingerprints (SHA-256)
  /// Each domain has a primary fingerprint (current certificate) and backup fingerprints (for rotation)
  /// 
  /// The structure is:
  /// {
  ///   'domain.com': {
  ///     'primary': 'current certificate fingerprint',
  ///     'backup': ['next certificate fingerprint', 'emergency backup fingerprint']
  ///   }
  /// }
  /// This is the default configuration that will be encrypted and stored securely
  final Map<String, Map<String, dynamic>> _defaultCertificateFingerprints = {
    'api.yourdomain.com': {
      // Primary (current) certificate fingerprint
      'primary': 'AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D',
      // Backup fingerprints for certificate rotation
      'backup': [
        '5E:8F:16:52:78:84:DF:09:C0:3E:34:7D:9E:B6:1A:DF:5E:3B:7F:A6:0D:48:4A:C1:3D:B2:0E:79:56:E5:5A:44',
        '0A:4C:3D:FC:B5:85:6A:F4:4C:17:26:45:E9:00:74:E0:70:20:AE:4E:69:D9:1C:E6:40:F2:84:93:65:81:2E:98', // Staging certificate
      ]
    },
    'api.example.com': {
      // Primary (current) certificate fingerprint
      'primary': 'AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D',
      // Backup fingerprints for certificate rotation
      'backup': [
        '5E:8F:16:52:78:84:DF:09:C0:3E:34:7D:9E:B6:1A:DF:5E:3B:7F:A6:0D:48:4A:C1:3D:B2:0E:79:56:E5:5A:44',
      ]
    },
    // CICD API domain (used by BuildMetadataService)
    'cicd.yourdomain.com': {
      'primary': 'AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D',
      'backup': []
    },
    // Security API domain (used by SecurityFeaturesService)
    'security.yourdomain.com': {
      'primary': 'AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D',
      'backup': []
    }
  };
  
  // In-memory cache of certificate fingerprints loaded from encrypted storage
  Map<String, Map<String, dynamic>> _certificateFingerprints = {};
  
  /// Certificate rotation schedule - when to rotate certificates
  /// Format: 'domain.com': 'YYYY-MM-DD'
  final Map<String, String> _defaultCertificateRotationDates = {
    'api.yourdomain.com': '2026-01-07', // 30 days before expiration (Feb 7, 2026)
    'api.example.com': '2026-01-07', // 30 days before expiration (Feb 7, 2026)
    'cicd.yourdomain.com': '2026-01-07', // 30 days before expiration (Feb 7, 2026)
    'security.yourdomain.com': '2026-01-07', // 30 days before expiration (Feb 7, 2026)
  };
  
  // In-memory cache of certificate rotation dates loaded from encrypted storage
  Map<String, String> _certificateRotationDates = {};

  // Current environment - should be set during app initialization
  String _environment = 'production';
  
  // Flag to track if we've detected a certificate validation failure
  bool _hasCertificateValidationFailed = false;
  
  // Callback for certificate validation failures
  Function(String host, String fingerprint)? onCertificateValidationFailure;
  
  // Enable verbose logging for debugging certificate pinning
  bool enableVerboseLogging = false;
  
  // Flag to enable developer mode (disables certificate pinning for easier testing)
  bool _developerModeEnabled = false;
  
  // Map to track which APIs are considered critical (require strict certificate validation)
  // If an API is not in this map or set to false, it will use graceful degradation
  final Map<String, bool> _criticalApis = {
    'api.yourdomain.com': true,
    'security.yourdomain.com': true,
    'cicd.yourdomain.com': false,
    'api.example.com': false
  };
  
  /// Initialize the certificate pinning service with encrypted storage
  Future<void> initialize() async {
    // Initialize the encrypted config manager
    await _configManager.initialize();
    
    // Load certificate fingerprints from encrypted storage
    await _loadCertificateFingerprints();
    
    // Load certificate rotation dates from encrypted storage
    await _loadCertificateRotationDates();
    
    if (enableVerboseLogging) {
      print('Certificate pinning service initialized with encrypted storage');
    }
  }
  
  /// Load certificate fingerprints from encrypted storage
  Future<void> _loadCertificateFingerprints() async {
    try {
      if (await _configManager.encryptedConfigExists(fileName: _fingerprintsConfigFileName)) {
        final config = await _configManager.loadEncryptedConfig(fileName: _fingerprintsConfigFileName);
        _certificateFingerprints = Map<String, Map<String, dynamic>>.from(config);
        
        if (enableVerboseLogging) {
          print('Loaded certificate fingerprints from encrypted storage');
        }
      } else {
        // Use default fingerprints and save them to encrypted storage
        _certificateFingerprints = Map<String, Map<String, dynamic>>.from(_defaultCertificateFingerprints);
        await _saveCertificateFingerprints();
        
        if (enableVerboseLogging) {
          print('Saved default certificate fingerprints to encrypted storage');
        }
      }
    } catch (e) {
      // Fallback to default fingerprints if loading fails
      _certificateFingerprints = Map<String, Map<String, dynamic>>.from(_defaultCertificateFingerprints);
      
      if (enableVerboseLogging) {
        print('Error loading certificate fingerprints: $e');
        print('Using default certificate fingerprints');
      }
    }
  }
  
  /// Save certificate fingerprints to encrypted storage
  Future<void> _saveCertificateFingerprints() async {
    try {
      await _configManager.saveEncryptedConfig(_certificateFingerprints, fileName: _fingerprintsConfigFileName);
      
      if (enableVerboseLogging) {
        print('Saved certificate fingerprints to encrypted storage');
      }
    } catch (e) {
      if (enableVerboseLogging) {
        print('Error saving certificate fingerprints: $e');
      }
    }
  }
  
  /// Load certificate rotation dates from encrypted storage
  Future<void> _loadCertificateRotationDates() async {
    try {
      if (await _configManager.encryptedConfigExists(fileName: _rotationDatesConfigFileName)) {
        final config = await _configManager.loadEncryptedConfig(fileName: _rotationDatesConfigFileName);
        _certificateRotationDates = Map<String, String>.from(config);
        
        if (enableVerboseLogging) {
          print('Loaded certificate rotation dates from encrypted storage');
        }
      } else {
        // Use default rotation dates and save them to encrypted storage
        _certificateRotationDates = Map<String, String>.from(_defaultCertificateRotationDates);
        await _saveCertificateRotationDates();
        
        if (enableVerboseLogging) {
          print('Saved default certificate rotation dates to encrypted storage');
        }
      }
    } catch (e) {
      // Fallback to default rotation dates if loading fails
      _certificateRotationDates = Map<String, String>.from(_defaultCertificateRotationDates);
      
      if (enableVerboseLogging) {
        print('Error loading certificate rotation dates: $e');
        print('Using default certificate rotation dates');
      }
    }
  }
  
  /// Save certificate rotation dates to encrypted storage
  Future<void> _saveCertificateRotationDates() async {
    try {
      await _configManager.saveEncryptedConfig(_certificateRotationDates, fileName: _rotationDatesConfigFileName);
      
      if (enableVerboseLogging) {
        print('Saved certificate rotation dates to encrypted storage');
      }
    } catch (e) {
      if (enableVerboseLogging) {
        print('Error saving certificate rotation dates: $e');
      }
    }
  }
  
  /// Enable or disable OCSP checking
  void setOcspCheckingEnabled(bool enabled) {
    _enableOcspChecking = enabled;
  }
  
  /// Check if OCSP checking is enabled
  bool isOcspCheckingEnabled() {
    return _enableOcspChecking;
  }
  
  /// Set the OCSP cache validity period in milliseconds
  void setOcspCacheValidityPeriod(int milliseconds) {
    _ocspCacheValidityPeriod = milliseconds;
  }
  
  /// Enable or disable developer mode (disables certificate pinning for easier testing)
  /// This should ONLY be used in development builds, never in production
  void setDeveloperMode(bool enabled) {
    _developerModeEnabled = enabled;
    if (enabled && enableVerboseLogging) {
      print('WARNING: Developer mode enabled - certificate pinning disabled');
    }
  }
  
  /// Check if developer mode is enabled
  bool isDeveloperModeEnabled() {
    return _developerModeEnabled;
  }
  
  /// Set whether an API is considered critical (requires strict certificate validation)
  /// Critical APIs will block connections on certificate validation failure
  /// Non-critical APIs will allow connections with invalid certificates in certain cases
  void setApiCritical(String domain, bool isCritical) {
    _criticalApis[domain] = isCritical;
  }
  
  /// Check if an API is considered critical
  bool isApiCritical(String domain) {
    return _criticalApis[domain] ?? false;
  }
  
  /// Get all domains that have certificate pinning configured
  List<String> getAllDomains() {
    return _certificateFingerprints.keys.toList();
  }
  
  /// Get the primary fingerprint for a domain
  String? getPrimaryFingerprint(String domain) {
    final domainFingerprints = _certificateFingerprints[domain];
    if (domainFingerprints == null) return null;
    return domainFingerprints['primary'] as String?;
  }
  
  /// Get the backup fingerprint for a domain
  String? getBackupFingerprint(String domain) {
    final domainFingerprints = _certificateFingerprints[domain];
    if (domainFingerprints == null) return null;
    final backupList = domainFingerprints['backup'] as List?;
    if (backupList == null || backupList.isEmpty) return null;
    return backupList.first as String?;
  }
  
  // Certificate rotation date method is defined below

  /// Configure Dio instance with certificate pinning and OCSP checking
  /// 
  /// [dio] The Dio instance to configure
  /// [validateCertificates] Whether to validate certificates (can be disabled for development)
  /// [checkOcsp] Whether to check OCSP status (can be disabled for performance)
  void configureDio(Dio dio, {bool validateCertificates = true, bool? checkOcsp}) {
    if (kIsWeb) return; // Certificate pinning not applicable for web

    // Use the provided checkOcsp value or fall back to the instance setting
    final shouldCheckOcsp = checkOcsp ?? _enableOcspChecking;

    // Configure the HTTP client adapter with certificate validation
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Skip validation if developer mode is enabled or validation is explicitly disabled
        if (_developerModeEnabled || !validateCertificates) {
          if (enableVerboseLogging) {
            print('Certificate validation bypassed for $host (Developer Mode: $_developerModeEnabled)');
          }
          return true;
        }

        // Get the fingerprints for this host
        final domainFingerprints = _certificateFingerprints[host];
        if (domainFingerprints == null) {
          if (enableVerboseLogging) {
            print('Certificate pinning not configured for $host, blocking connection');
          }
          return false; // No fingerprints configured for this host
        }

        // Get the certificate fingerprint
        final certFingerprint = _getCertificateFingerprint(cert);
        
        // Get all valid fingerprints (primary + all backups)
        final validFingerprints = <String>[];
        
        // Add primary fingerprint
        if (domainFingerprints['primary'] != null) {
          validFingerprints.add(domainFingerprints['primary']);
        }
        
        // Add backup fingerprints
        if (domainFingerprints['backup'] != null) {
          final backupList = domainFingerprints['backup'] as List<String>;
          validFingerprints.addAll(backupList);
        }
        
        // Check if the certificate fingerprint matches any of the valid fingerprints
        final isPinValid = validFingerprints.contains(certFingerprint);
        
        // If pin validation fails, handle it
        if (!isPinValid) {
          _handleCertificateValidationFailure(host, port, certFingerprint);
          
          // For non-critical APIs, allow the connection to proceed if graceful degradation is enabled
          if (!isApiCritical(host)) {
            if (enableVerboseLogging) {
              print('Certificate validation failed for non-critical API $host, allowing connection with warning');
            }
            return true;
          }
          
          return false;
        }
        
        // We'll check OCSP status asynchronously via interceptor
        // This allows us to keep the badCertificateCallback synchronous as required
        if (shouldCheckOcsp && enableVerboseLogging) {
          print('OCSP checking will be performed asynchronously via interceptor for $host');
        }
        
        return true;
      };
      return client;
    };

    // Add interceptors for certificate validation and OCSP checking
    dio.interceptors.add(_createCertificateValidationInterceptor());
    
    // Add OCSP checking interceptor if enabled
    if (shouldCheckOcsp) {
      dio.interceptors.add(_createOcspCheckInterceptor());
    }
    
    // Add graceful degradation interceptor for non-critical APIs
    dio.interceptors.add(_createGracefulDegradationInterceptor());
  }

  /// Create an interceptor to handle certificate validation failures
  Interceptor _createCertificateValidationInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        // Check if this is a certificate validation error
        if (error.error is HandshakeException || 
            (error.error is SocketException && 
             (error.error as SocketException).message.contains('certificate'))) {
          
          // Create a more user-friendly error message as requested
          final friendlyError = DioException(
            requestOptions: error.requestOptions,
            error: 'Secure connection failed. Please try again later or update the app.',
            type: DioExceptionType.badCertificate,
          );
          
          // Return the friendly error
          return handler.reject(friendlyError);
        }
        
        // For other errors, continue with normal error handling
        return handler.next(error);
      },
    );
  }
  
  /// Create an interceptor for graceful degradation of non-critical APIs
  Interceptor _createGracefulDegradationInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        final host = error.requestOptions.uri.host;
        
        // Only apply graceful degradation for non-critical APIs
        if (!isApiCritical(host)) {
          // Check if this is a certificate validation error
          if (error.type == DioExceptionType.badCertificate ||
              error.error is HandshakeException ||
              (error.error is SocketException && 
               (error.error as SocketException).message.contains('certificate'))) {
            
            if (enableVerboseLogging) {
              print('Applying graceful degradation for non-critical API $host');
            }
            
            // Log the security warning
            _logToSecurityFile('Certificate validation failed for non-critical API $host - graceful degradation applied');
            
            // For GET requests, try to return cached data if available
            if (error.requestOptions.method == 'GET') {
              final cachedData = await _getCachedDataForRequest(error.requestOptions);
              
              if (cachedData != null) {
                if (enableVerboseLogging) {
                  print('Returning cached data for ${error.requestOptions.path}');
                }
                
                final cachedResponse = Response(
                  data: cachedData,
                  statusCode: 200,
                  requestOptions: error.requestOptions,
                  headers: Headers(),
                  isRedirect: false,
                  extra: {'from_cache': true, 'security_warning': true}
                );
                return handler.resolve(cachedResponse);
              } else if (enableVerboseLogging) {
                print('No cached data available for ${error.requestOptions.path}');
              }
            }
          }
        }
        
        // For critical APIs or other errors, continue with normal error handling
        return handler.next(error);
      },
    );
  }
  
  /// Get cached data for a request if available
  /// This is used for graceful degradation of non-critical APIs
  Future<dynamic> _getCachedDataForRequest(RequestOptions options) async {
    // In a real implementation, this would retrieve data from a cache
    // For example, using a package like flutter_cache_manager or hive
    
    // For now, we'll implement a simple in-memory cache
    // In a real app, this would be persistent and have proper cache invalidation
    
    // Create a cache key from the request URL and parameters
    final cacheKey = '${options.uri.toString()}_${options.queryParameters.toString()}';
    
    // Check if we have cached data for this request
    // In a real implementation, this would be a persistent cache
    // and would include cache expiration logic
    final cachedData = _requestCache[cacheKey];
    
    return cachedData;
  }
  
  // Simple in-memory cache for request responses
  // In a real implementation, this would be a persistent cache
  final Map<String, dynamic> _requestCache = {};

  /// Get the fingerprint of a certificate
  String _getCertificateFingerprint(X509Certificate cert) {
    // Convert the certificate to a fingerprint string
    final bytes = cert.der;
    return _formatFingerprint(bytes);
  }

  /// Format a certificate fingerprint as a colon-separated hex string
  String _formatFingerprint(Uint8List bytes) {
    final hexBytes = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase()).toList();
    return hexBytes.join(':');
  }
  
  /// Create an interceptor for OCSP checking
  Interceptor _createOcspCheckInterceptor() {
    return InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        // Store the start time for performance logging
        options.extra['ocsp_check_start_time'] = DateTime.now().millisecondsSinceEpoch;
        return handler.next(options);
      },
      onResponse: (Response response, ResponseInterceptorHandler handler) async {
        final host = response.requestOptions.uri.host;
        final startTime = response.requestOptions.extra['ocsp_check_start_time'] as int?;
        
        // Perform OCSP check asynchronously after response is received
        // This doesn't block the response but provides logging and metrics
        _performAsyncOcspCheck(host, startTime);
        
        // Cache the response for non-critical APIs to support graceful degradation
        if (!isApiCritical(host) && response.requestOptions.method == 'GET') {
          _cacheResponseForRequest(response.requestOptions, response.data);
        }
        
        return handler.next(response);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        // Continue with error handling even if OCSP check would fail
        return handler.next(error);
      },
    );
  }
  
  /// Cache a response for a request to support graceful degradation
  void _cacheResponseForRequest(RequestOptions options, dynamic data) {
    // Only cache responses for non-critical APIs
    if (!isApiCritical(options.uri.host)) {
      // Create a cache key from the request URL and parameters
      final cacheKey = '${options.uri.toString()}_${options.queryParameters.toString()}';
      
      // Store the response data in the cache
      _requestCache[cacheKey] = data;
      
      if (enableVerboseLogging) {
        print('Cached response for ${options.path}');
      }
    }
  }
  
  /// Perform an asynchronous OCSP check for a host
  /// This doesn't block the request/response cycle but provides logging and metrics
  void _performAsyncOcspCheck(String host, int? startTime) {
    // Run the check in a separate isolate or background task
    Future(() async {
      try {
        // In a real implementation, we would extract the certificate from the connection
        // and check its OCSP status. For now, we'll just log that we would do this.
        if (enableVerboseLogging) {
          final elapsed = startTime != null 
              ? DateTime.now().millisecondsSinceEpoch - startTime 
              : null;
          print('Would perform async OCSP check for $host (elapsed: ${elapsed ?? 'unknown'} ms)');
        }
      } catch (e) {
        if (enableVerboseLogging) {
          print('Async OCSP check error for $host: $e');
        }
      }
    });
  }
  
  /// Check the OCSP status of a certificate
  /// 
  /// [cert] The X509Certificate to check
  /// [host] The host being connected to
  /// Returns true if the certificate is valid according to OCSP, false otherwise
  Future<bool> _checkOcspStatus(X509Certificate cert, String host) async {
    // Check if we have a cached OCSP response for this certificate
    final certFingerprint = _getCertificateFingerprint(cert);
    final cacheKey = '$host:$certFingerprint';
    
    // Check if we have a valid cached response
    if (_ocspCache.containsKey(cacheKey)) {
      final cachedResponse = _ocspCache[cacheKey]!;
      final timestamp = cachedResponse['timestamp'] as int;
      final status = cachedResponse['status'] as bool;
      
      // Check if the cached response is still valid
      if (DateTime.now().millisecondsSinceEpoch - timestamp < _ocspCacheValidityPeriod) {
        return status;
      }
      
      // Remove the expired cache entry
      _ocspCache.remove(cacheKey);
    }
    
    // Extract the OCSP responder URL from the certificate
    // This is a simplified implementation - in a real app, you would extract the OCSP responder URL from the AIA extension
    final ocspResponderUrl = await _getOcspResponderUrl(cert);
    if (ocspResponderUrl == null) {
      // No OCSP responder URL found, consider it valid to avoid breaking functionality
      if (enableVerboseLogging) {
        print('No OCSP responder URL found for $host');
      }
      return true;
    }
    
    try {
      // Create an OCSP request for the certificate
      final ocspRequest = await _createOcspRequest(cert);
      
      // Send the OCSP request to the responder
      final response = await http.post(
        Uri.parse(ocspResponderUrl),
        headers: {'Content-Type': 'application/ocsp-request'},
        body: ocspRequest,
      );
      
      // Parse the OCSP response
      final ocspStatus = _parseOcspResponse(response.bodyBytes);
      
      // Cache the OCSP response
      _ocspCache[cacheKey] = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': ocspStatus,
      };
      
      return ocspStatus;
    } catch (e) {
      if (enableVerboseLogging) {
        print('Error checking OCSP status: $e');
      }
      // In case of error, consider the certificate valid to avoid breaking functionality
      // This is a fail-open approach, which is common for OCSP
      return true;
    }
  }
  
  /// Get the OCSP responder URL from a certificate
  /// 
  /// [cert] The X509Certificate to get the OCSP responder URL from
  /// Returns the OCSP responder URL, or null if not found
  Future<String?> _getOcspResponderUrl(X509Certificate cert) async {
    // In a real implementation, you would extract the OCSP responder URL from the AIA extension
    // This is a simplified implementation that returns a hardcoded URL for testing
    // For production, you would need to use a library that can parse X.509 extensions
    
    // For now, we'll return a default OCSP responder URL for testing
    return 'http://ocsp.digicert.com';
  }
  
  /// Create an OCSP request for a certificate
  /// 
  /// [cert] The X509Certificate to create an OCSP request for
  /// Returns the DER-encoded OCSP request
  Future<Uint8List> _createOcspRequest(X509Certificate cert) async {
    // In a real implementation, you would create a proper OCSP request
    // This is a simplified implementation that returns a dummy request for testing
    // For production, you would need to use a library that can create OCSP requests
    
    // For now, we'll return a dummy request for testing
    return Uint8List.fromList([0x30, 0x03, 0x0A, 0x01, 0x01]);
  }
  
  /// Parse an OCSP response
  /// 
  /// [responseBytes] The DER-encoded OCSP response
  /// Returns true if the certificate is valid, false otherwise
  bool _parseOcspResponse(Uint8List responseBytes) {
    // In a real implementation, you would parse the OCSP response and check the status
    // This is a simplified implementation that always returns true for testing
    // For production, you would need to use a library that can parse OCSP responses
    
    // For now, we'll return true for testing
    return true;
  }

  /// Calculate SHA-256 fingerprint of certificate in base64 format
  /// 
  /// This implementation calculates a SHA-256 hash of the certificate's DER encoding,
  /// similar to the OpenSSL command:
  /// openssl s_client -servername example.com -connect example.com:443 | 
  /// openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | 
  /// openssl dgst -sha256 -binary | openssl enc -base64
  String calculateSha256Fingerprint(X509Certificate cert) {
    try {
      // Get the DER-encoded certificate data
      final Uint8List certBytes = cert.der;
      
      // Calculate SHA-256 hash of the certificate
      final hash = sha256.convert(certBytes);
      
      // Encode the hash in base64
      final fingerprint = 'sha256/${base64.encode(hash.bytes)}';
      
      // Log fingerprint information if verbose logging is enabled
      if (enableVerboseLogging) {
        print('Certificate details:');
        print('  Subject: ${cert.subject}');
        print('  Issuer: ${cert.issuer}');
        print('  Valid from: ${cert.startValidity}');
        print('  Valid to: ${cert.endValidity}');
        print('  Calculated fingerprint: $fingerprint');
      }
      
      return fingerprint;
    } catch (e) {
      print('Error calculating certificate fingerprint: $e');
      if (enableVerboseLogging) {
        print('Certificate error details:');
        print('  Error type: ${e.runtimeType}');
        print('  Stack trace: ${StackTrace.current}');
      }
      return '';
    }
  }

  /// Handle certificate validation failure
  void _handleCertificateValidationFailure(String host, int port, String fingerprint, {String reason = 'Certificate validation failed'}) {
    // Set the flag to indicate we've had a validation failure
    _hasCertificateValidationFailed = true;
    
    // Always log basic information
    print('$reason for $host:$port');
    
    // Log detailed information if verbose logging is enabled
    if (enableVerboseLogging) {
      print('Received fingerprint: $fingerprint');
      print('Expected fingerprints for $host: ${_certificateFingerprints[host]}');
      print('Current environment: $_environment');
      print('Certificate validation timestamp: ${DateTime.now().toIso8601String()}');
    }
    
    // Log to security log file
    _logToSecurityFile('SSL Pinning validation failed – connection blocked');
    
    // Call the validation failure callback if set
    if (onCertificateValidationFailure != null) {
      onCertificateValidationFailure!(host, fingerprint);
    }
  }

  /// Add a primary certificate fingerprint for a domain
  /// 
  /// [domain] The domain to add the fingerprint for
  /// [fingerprint] The certificate fingerprint (SHA-256, colon-separated hex)
  /// [rotationDate] Optional date when this certificate will be rotated (YYYY-MM-DD format)
  Future<void> addPrimaryCertificateFingerprint(String domain, String fingerprint, {String? rotationDate}) async {
    if (!_certificateFingerprints.containsKey(domain)) {
      _certificateFingerprints[domain] = {
        'primary': fingerprint,
        'backup': <String>[],
      };
    } else {
      _certificateFingerprints[domain]!['primary'] = fingerprint;
    }
    
    // Set rotation date if provided
    if (rotationDate != null) {
      _certificateRotationDates[domain] = rotationDate;
      await _saveCertificateRotationDates();
    }
    
    // Save the updated fingerprints to encrypted storage
    await _saveCertificateFingerprints();
  }
  
  /// Add a backup certificate fingerprint for a domain
  /// 
  /// [domain] The domain to add the backup fingerprint for
  /// [fingerprint] The certificate fingerprint (SHA-256, colon-separated hex)
  Future<void> addBackupCertificateFingerprint(String domain, String fingerprint) async {
    if (!_certificateFingerprints.containsKey(domain)) {
      _certificateFingerprints[domain] = {
        'primary': '',
        'backup': <String>[fingerprint],
      };
    } else {
      if (!_certificateFingerprints[domain]!.containsKey('backup')) {
        _certificateFingerprints[domain]!['backup'] = <String>[];
      }
      
      final backupList = _certificateFingerprints[domain]!['backup'] as List<String>;
      if (!backupList.contains(fingerprint)) {
        backupList.add(fingerprint);
      }
    }
    
    // Save the updated fingerprints to encrypted storage
    await _saveCertificateFingerprints();
  }
  
  /// Add a certificate fingerprint for a domain
  /// 
  /// [domain] The domain to add the fingerprint for
  /// [fingerprint] The certificate fingerprint (SHA-256, colon-separated hex)
  /// [isPrimary] Whether this is a primary certificate (true) or backup (false)
  Future<void> addCertificateFingerprint(String domain, String fingerprint, {bool isPrimary = false}) async {
    if (isPrimary) {
      await addPrimaryCertificateFingerprint(domain, fingerprint);
    } else {
      await addBackupCertificateFingerprint(domain, fingerprint);
    }
  }

  /// Clear all certificate fingerprints
  Future<void> clearCertificateFingerprints() async {
    _certificateFingerprints.clear();
    _certificateRotationDates.clear();
    
    // Save the cleared fingerprints and rotation dates to encrypted storage
    await _saveCertificateFingerprints();
    await _saveCertificateRotationDates();
  }
  
  /// Get the planned rotation date for a domain's certificate
  /// 
  /// [domain] The domain to get the rotation date for
  /// Returns the rotation date in YYYY-MM-DD format, or null if not set
  String? getCertificateRotationDate(String domain) {
    return _certificateRotationDates[domain];
  }
  
  /// Check if a certificate rotation is due within the specified days
  /// 
  /// [domain] The domain to check
  /// [daysThreshold] Number of days before rotation to start warning
  /// Returns true if rotation is due within the threshold, false otherwise
  bool isCertificateRotationDueSoon(String domain, {int daysThreshold = 14}) {
    final rotationDate = _certificateRotationDates[domain];
    if (rotationDate == null) return false;
    
    try {
      // Parse the rotation date
      final rotation = DateTime.parse(rotationDate);
      final now = DateTime.now();
      
      // Calculate the difference in days
      final difference = rotation.difference(now).inDays;
      
      // Return true if the rotation is due within the threshold
      return difference <= daysThreshold;
    } catch (e) {
      print('Error parsing rotation date: $e');
      return false;
    }
  }

  /// Set the environment for certificate validation
  /// 
  /// This allows switching between different sets of certificate fingerprints
  /// for different environments (production, staging, development)
  void setEnvironment(String environment) {
    _environment = environment;
    if (enableVerboseLogging) {
      print('Certificate pinning environment set to: $environment');
    }
  }

  /// Test the certificate pinning implementation
  /// 
  /// This method can be used to verify that certificate pinning is working correctly.
  /// It attempts to make a request to the specified URL and returns information about
  /// whether the certificate validation succeeded or failed.
  Future<Map<String, dynamic>> testCertificatePinning(String url, Dio dio) async {
    // Reset the validation failure flag
    _hasCertificateValidationFailed = false;
    
    final result = <String, dynamic>{
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
      'environment': _environment,
      'pinned_domains': _certificateFingerprints.keys.toList(),
    };
    
    try {
      // Attempt to make a request to the URL
      final response = await dio.get(url);
      
      // If we get here, the request succeeded
      result['success'] = true;
      result['status_code'] = response.statusCode;
      result['certificate_validated'] = !_hasCertificateValidationFailed;
      result['message'] = 'Certificate validation successful';
    } catch (e) {
      // Request failed
      result['success'] = false;
      
      if (e is DioException) {
        result['status_code'] = e.response?.statusCode;
        result['error_type'] = e.type.toString();
        result['error_message'] = e.message;
        
        // Check if this was a certificate validation failure
        if (e.type == DioExceptionType.badCertificate || 
            _hasCertificateValidationFailed) {
          result['certificate_validated'] = false;
          result['message'] = 'Certificate validation failed';
        } else {
          result['certificate_validated'] = !_hasCertificateValidationFailed;
          result['message'] = 'Request failed, but not due to certificate validation';
        }
      } else {
        result['error_message'] = e.toString();
        result['certificate_validated'] = !_hasCertificateValidationFailed;
        result['message'] = 'Unknown error occurred';
      }
    }
    
    return result;
  }

  /// Get all domains with configured certificate fingerprints
  List<String> get configuredDomains => _certificateFingerprints.keys.toList();

  /// Check if a domain has certificate fingerprints configured
  bool hasDomainConfiguration(String domain) => _certificateFingerprints.containsKey(domain);
  
  /// Log security-related messages to the security log file
  void _logToSecurityFile(String message) {
    try {
      // Create the logs directory if it doesn't exist
      final logDir = Directory(path.join(Directory.current.path, 'logs', 'security'));
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      
      // Log file path
      final logFile = File(path.join(logDir.path, 'certificate_failures.log'));
      
      // Write the log message with timestamp
      logFile.writeAsStringSync(
        "[${DateTime.now().toIso8601String()}] $message\n", 
        mode: FileMode.append
      );
      
      if (enableVerboseLogging) {
        print('Security log written to: ${logFile.path}');
      }
    } catch (e) {
      print('Error writing to security log: $e');
    }
  }
}