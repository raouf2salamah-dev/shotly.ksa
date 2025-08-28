import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'certificate_pinning_service.dart';

/// DioPinning provides certificate pinning functionality for Dio HTTP client
/// 
/// This class is now a wrapper around the centralized CertificatePinningService.
/// It maintains the same API for backward compatibility but delegates all
/// certificate pinning operations to CertificatePinningService.
class DioPinning {
  // Get the singleton instance of CertificatePinningService
  static final CertificatePinningService _service = CertificatePinningService();

  /// Configure Dio instance with certificate pinning
  /// 
  /// [dio] The Dio instance to configure
  /// [validateCertificates] Whether to validate certificates (can be disabled for development)
  static void configureDio(Dio dio, {bool validateCertificates = true}) {
    if (kIsWeb) return; // Certificate pinning not applicable for web
    
    // Delegate to the centralized certificate pinning service
    _service.configureDio(dio, validateCertificates: validateCertificates);
  }

  // Private methods are now handled by the centralized service

  /// Add a primary certificate fingerprint for a domain
  /// 
  /// [domain] The domain to add the fingerprint for
  /// [fingerprint] The certificate fingerprint (SHA-256, colon-separated hex)
  /// [rotationDate] Optional date when this certificate will be rotated (YYYY-MM-DD format)
  static void addPrimaryCertificateFingerprint(String domain, String fingerprint, {String? rotationDate}) {
    _service.addPrimaryCertificateFingerprint(domain, fingerprint, rotationDate: rotationDate);
  }
  
  /// Add a backup certificate fingerprint for a domain
  /// 
  /// [domain] The domain to add the backup fingerprint for
  /// [fingerprint] The certificate fingerprint (SHA-256, colon-separated hex)
  static void addBackupCertificateFingerprint(String domain, String fingerprint) {
    _service.addBackupCertificateFingerprint(domain, fingerprint);
  }
  
  /// Add a certificate fingerprint for a domain (legacy method)
  /// 
  /// [domain] The domain to add the fingerprint for
  /// [fingerprint] The certificate fingerprint (SHA-256, colon-separated hex)
  /// [isPrimary] Whether this is a primary certificate (true) or backup (false)
  static void addCertificateFingerprint(String domain, String fingerprint, {bool isPrimary = false}) {
    _service.addCertificateFingerprint(domain, fingerprint, isPrimary: isPrimary);
  }

  /// Clear all certificate fingerprints
  static void clearCertificateFingerprints() {
    _service.clearCertificateFingerprints();
  }
  
  /// Get the planned rotation date for a domain's certificate
  /// 
  /// [domain] The domain to get the rotation date for
  /// Returns the rotation date in YYYY-MM-DD format, or null if not set
  static String? getCertificateRotationDate(String domain) {
    return _service.getCertificateRotationDate(domain);
  }
  
  /// Check if a certificate rotation is due within the specified days
  /// 
  /// [domain] The domain to check
  /// [daysThreshold] Number of days before rotation to start warning
  /// Returns true if rotation is due within the threshold, false otherwise
  static bool isCertificateRotationDueSoon(String domain, {int daysThreshold = 14}) {
    return _service.isCertificateRotationDueSoon(domain, daysThreshold: daysThreshold);
  }
  
  /// Get a list of all domains that have certificate configurations
  static List<String> get configuredDomains {
    return _service.configuredDomains;
  }
  
  /// Check if a domain has certificate configuration
  static bool hasDomainConfiguration(String domain) {
    return _service.hasDomainConfiguration(domain);
  }
}