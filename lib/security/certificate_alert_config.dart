import 'package:flutter/material.dart';
import 'certificate_expiration_service.dart';
import 'certificate_pinning_service.dart';
import '../bootstrap/security_bootstrap.dart';

/// A class to configure and manage certificate expiration alerts
class CertificateAlertConfig {
  /// Singleton instance
  static final CertificateAlertConfig _instance = CertificateAlertConfig._internal();
  
  /// Factory constructor to return the singleton instance
  factory CertificateAlertConfig() => _instance;
  
  /// Private constructor for singleton pattern
  CertificateAlertConfig._internal() {
    // Set default alert threshold to 30 days
    _expirationService.setAlertThreshold(30);
  }
  
  /// Reference to the certificate expiration service
  final CertificateExpirationService _expirationService = CertificateExpirationService();
  
  /// List of domains to monitor for certificate expiration
  final List<String> _monitoredDomains = [];
  
  /// Add a domain to monitor for certificate expiration
  void addDomainToMonitor(String domain) {
    if (!_monitoredDomains.contains(domain)) {
      _monitoredDomains.add(domain);
    }
  }
  
  /// Remove a domain from monitoring
  void removeDomainFromMonitor(String domain) {
    _monitoredDomains.remove(domain);
  }
  
  /// Get all monitored domains
  List<String> getMonitoredDomains() {
    return List.from(_monitoredDomains);
  }
  
  /// Set the number of days before expiration to trigger an alert
  void setAlertThreshold(int days) {
    _expirationService.setAlertThreshold(days);
  }
  
  /// Get the current alert threshold in days
  int getAlertThreshold() {
    return _expirationService.getAlertThreshold();
  }
  
  /// Check all monitored domains for certificate expiration
  Future<void> checkAllDomains() async {
    await _expirationService.checkAllDomains(_monitoredDomains);
  }
  
  /// Show alerts for certificates that are about to expire
  void showExpirationAlerts(BuildContext context) {
    _expirationService.showExpirationAlerts(context);
  }
  
  /// Check for expiring certificates and show alerts if needed
  void checkAndNotify(BuildContext context) async {
    await checkAllDomains();
    showExpirationAlerts(context);
  }
  
  /// Initialize the alert configuration with domains from the certificate pinning service
  void initialize() {
    // Add domains from CertificatePinningService
    final pinningService = CertificatePinningService();
    final domains = pinningService.getAllDomains();
    for (final domain in domains) {
      addDomainToMonitor(domain);
    }
  }
}