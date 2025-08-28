import 'package:flutter/material.dart';
import '../security/certificate_alert_config.dart';
import '../security/certificate_expiration_service.dart';

/// A bootstrap class to initialize certificate alert configuration
class CertificateAlertBootstrap {
  /// Initialize certificate alert configuration
  static void initialize() {
    // Initialize certificate alert configuration
    final alertConfig = CertificateAlertConfig();
    alertConfig.initialize();
    
    // Set alert threshold to 30 days
    alertConfig.setAlertThreshold(30);
  }
  
  /// Check for certificate expiration and show alerts if needed
  static void checkAndNotify(BuildContext context) {
    final alertConfig = CertificateAlertConfig();
    alertConfig.checkAndNotify(context);
  }
}