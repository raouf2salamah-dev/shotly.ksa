import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../security/device_integrity.dart';
import '../security/secure_storage.dart';
import '../security/certificate_pinning_service.dart';
import '../security/certificate_alert_config.dart';
import '../network/auth_interceptor.dart';
import '../network/token_repository.dart';
import '../network/request_signer.dart';
import 'certificate_alert_bootstrap.dart';

/// SecurityBootstrap provides a centralized way to initialize all security features
/// 
/// This class should be called from main.dart during app initialization
class SecurityBootstrap {
  /// Singleton instance of Dio configured with security features
  static Dio? _dio;
  
  /// Singleton instance of CertificatePinningService
  static final CertificatePinningService _certificatePinningService = CertificatePinningService();
  
  /// Access the configured Dio instance
  static Dio get dio {
    if (_dio == null) {
      throw StateError('SecurityBootstrap not initialized. Call SecurityBootstrap.init() first.');
    }
    return _dio!;
  }
  
  /// Access the certificate pinning service
  static CertificatePinningService get certificatePinningService {
    return _certificatePinningService;
  }
  
  /// Initialize all security features
  /// 
  /// This should be called in main() before runApp()
  static Future<void> init({
    bool validateCertificates = true,
    bool checkDeviceIntegrity = true,
  }) async {
    _dio = await initialize(
      validateCertificates: validateCertificates,
      checkDeviceIntegrity: checkDeviceIntegrity,
    );
    
    // Initialize certificate alert configuration
    CertificateAlertBootstrap.initialize();
  }
  
  /// Check for certificate expiration and show alerts if needed
  static void checkCertificateExpiration(BuildContext context) {
    CertificateAlertBootstrap.checkAndNotify(context);
  }
  /// Initialize all security features
  /// 
  /// [dio] - Optional Dio instance to configure with security features
  /// [validateCertificates] - Whether to validate certificates (can be disabled for development)
  /// [checkDeviceIntegrity] - Whether to check device integrity (jailbreak/root detection)
  /// 
  /// Returns a configured Dio instance with security features
  static Future<Dio> initialize({
    Dio? dio,
    bool validateCertificates = true,
    bool checkDeviceIntegrity = true,
  }) async {
    // Create or use provided Dio instance
    final dioInstance = dio ?? Dio();
    
    // Configure certificate pinning
    if (!kIsWeb) {
      _certificatePinningService.configureDio(dioInstance, validateCertificates: validateCertificates);
      debugPrint('Certificate pinning configured');
    }
    
    // Add auth interceptor for token management
    dioInstance.interceptors.add(AuthInterceptor(dio: dioInstance, tokens: TokenRepository()));
    debugPrint('Auth interceptor added');
    
    // Check device integrity if enabled
    if (checkDeviceIntegrity && !kIsWeb) {
      final isCompromised = await DeviceIntegrity.isCompromised();
      if (isCompromised) {
        debugPrint('WARNING: Device integrity check failed - device may be compromised');
        // You can decide what to do if the device is compromised
        // For example, you could restrict certain features or show a warning
      } else {
        debugPrint('Device integrity check passed');
      }
    }
    
    return dioInstance;
  }
  
  /// Add custom certificate fingerprints for certificate pinning
  /// 
  /// [domain] - The domain to add the fingerprint for
  /// [fingerprint] - The certificate fingerprint (SHA-256, colon-separated hex)
  /// [isPrimary] - Whether this is a primary certificate (true) or backup (false)
  /// [rotationDate] - Optional date when this certificate will be rotated (YYYY-MM-DD format)
  static void addCertificateFingerprint(String domain, String fingerprint, {bool isPrimary = false, String? rotationDate}) {
    if (isPrimary) {
      _certificatePinningService.addPrimaryCertificateFingerprint(domain, fingerprint, rotationDate: rotationDate);
    } else {
      _certificatePinningService.addBackupCertificateFingerprint(domain, fingerprint);
    }
  }
  
  /// Check if a certificate rotation is due soon for a domain
  /// 
  /// [domain] - The domain to check
  /// [daysThreshold] - Number of days before rotation to start warning
  /// Returns true if rotation is due within the threshold, false otherwise
  static bool isCertificateRotationDueSoon(String domain, {int daysThreshold = 14}) {
    return _certificatePinningService.isCertificateRotationDueSoon(domain, daysThreshold: daysThreshold);
  }
  
  /// Get the planned rotation date for a domain's certificate
  /// 
  /// [domain] - The domain to get the rotation date for
  /// Returns the rotation date in YYYY-MM-DD format, or null if not set
  static String? getCertificateRotationDate(String domain) {
    return _certificatePinningService.getCertificateRotationDate(domain);
  }
  
  /// Test the certificate pinning implementation
  /// 
  /// [url] - The URL to test certificate pinning against
  /// Returns a map with the results of the test
  static Future<Map<String, dynamic>> testCertificatePinning(String url) {
    return _certificatePinningService.testCertificatePinning(url, dio);
  }
  
  /// Get all domains with configured certificate fingerprints
  static List<String> get configuredDomains => _certificatePinningService.configuredDomains;
  
  /// Check if a domain has certificate fingerprints configured
  static bool hasDomainConfiguration(String domain) => _certificatePinningService.hasDomainConfiguration(domain);
  
  /// Check if the device has a valid signing key for request signing
  /// 
  /// Returns true if a signing key is available
  static Future<bool> hasValidSigningKey() async {
    final key = await SecureStorage.getDeviceSigningKey();
    return key != null && key.isNotEmpty;
  }
  
  /// Generate a test signature to verify request signing functionality
  /// 
  /// Returns the generated signature or null if signing fails
  static Future<String?> generateTestSignature() async {
    return RequestSigner.signRequest(
      path: '/api/test',
      body: '{"test":true}',
    );
  }
  
  /// Get a detailed security report
  /// 
  /// Returns a map with the results of various security checks
  static Future<Map<String, dynamic>> getSecurityReport() async {
    final deviceReport = await DeviceIntegrity.getIntegrityReport();
    final hasSigningKey = await hasValidSigningKey();
    final hasAccessToken = await SecureStorage.getAccessToken() != null;
    
    return {
      'device_integrity': deviceReport,
      'has_signing_key': hasSigningKey,
      'has_access_token': hasAccessToken,
      'certificate_pinning_enabled': !kIsWeb,
    };
  }
  
  /// Build a new Dio instance with certificate pinning and auth interceptor
  /// 
  /// [baseUrl] - Optional base URL for the Dio instance
  /// [validateCertificates] - Whether to validate certificates
  /// [connectTimeout] - Connection timeout in milliseconds
  /// [receiveTimeout] - Receive timeout in milliseconds
  /// 
  /// Returns a new configured Dio instance
  static Dio buildPinnedDio({
    String? baseUrl,
    bool validateCertificates = true,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: Duration(milliseconds: connectTimeout),
      receiveTimeout: Duration(milliseconds: receiveTimeout),
      validateStatus: (status) => status != null && status < 500,
    );
    
    final dioInstance = Dio(options);
    
    // Configure certificate pinning
    if (!kIsWeb) {
      _certificatePinningService.configureDio(dioInstance, validateCertificates: validateCertificates);
    }
    
    // Add auth interceptor
    dioInstance.interceptors.add(AuthInterceptor(dio: dioInstance, tokens: TokenRepository()));
    
    return dioInstance;
  }
}