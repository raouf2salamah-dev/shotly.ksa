import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bootstrap/security_bootstrap.dart';
import 'certificate_pinning_service.dart';

/// A service that checks certificate expiration dates and provides alerts
/// when certificates are about to expire.
class CertificateExpirationService {
  /// Singleton instance
  static final CertificateExpirationService _instance = CertificateExpirationService._internal();
  
  /// Factory constructor to return the singleton instance
  factory CertificateExpirationService() => _instance;
  
  /// Private constructor for singleton pattern
  CertificateExpirationService._internal();
  
  /// Map of domains to their certificate expiration dates
  final Map<String, DateTime> _expirationDates = {};
  
  /// Days before expiration to trigger an alert
  int _alertThresholdDays = 30;
  
  /// Set the number of days before expiration to trigger an alert
  void setAlertThreshold(int days) {
    _alertThresholdDays = days;
  }
  
  /// Get the current alert threshold in days
  int getAlertThreshold() {
    return _alertThresholdDays;
  }
  
  /// Check the expiration date of a certificate for a domain using OpenSSL
  /// Returns the expiration date as a DateTime object
  Future<DateTime?> checkCertificateExpiration(String domain, {int port = 443}) async {
    try {
      // Use OpenSSL to get the certificate expiration date
      final result = await Process.run('sh', [
        '-c',
        'echo | openssl s_client -connect $domain:$port 2>/dev/null | openssl x509 -noout -enddate'
      ]);
      
      if (result.exitCode != 0) {
        print('Error checking certificate for $domain: ${result.stderr}');
        return null;
      }
      
      // Parse the output to get the expiration date
      // Output format: notAfter=May 17 12:00:00 2023 GMT
      final output = result.stdout.toString().trim();
      final match = RegExp(r'notAfter=(.+)').firstMatch(output);
      
      if (match == null) {
        print('Could not parse expiration date for $domain');
        return null;
      }
      
      final dateStr = match.group(1)!;
      // Parse the date string to a DateTime object
      // Format: MMM dd HH:mm:ss yyyy GMT
      final dateFormat = DateFormat('MMM dd HH:mm:ss yyyy zzz');
      final expirationDate = dateFormat.parse(dateStr);
      
      // Store the expiration date
      _expirationDates[domain] = expirationDate;
      
      return expirationDate;
    } catch (e) {
      print('Exception checking certificate for $domain: $e');
      return null;
    }
  }
  
  /// Check if a certificate is about to expire based on the alert threshold
  bool isCertificateAboutToExpire(String domain) {
    final expirationDate = _expirationDates[domain];
    if (expirationDate == null) {
      return false;
    }
    
    final now = DateTime.now();
    final daysUntilExpiration = expirationDate.difference(now).inDays;
    
    return daysUntilExpiration <= _alertThresholdDays;
  }
  
  /// Get the number of days until a certificate expires
  int? getDaysUntilExpiration(String domain) {
    final expirationDate = _expirationDates[domain];
    if (expirationDate == null) {
      return null;
    }
    
    final now = DateTime.now();
    return expirationDate.difference(now).inDays;
  }
  
  /// Get the expiration date for a domain
  DateTime? getExpirationDate(String domain) {
    return _expirationDates[domain];
  }
  
  /// Get a formatted string of the expiration date for a domain
  String? getFormattedExpirationDate(String domain) {
    final expirationDate = _expirationDates[domain];
    if (expirationDate == null) {
      return null;
    }
    
    return DateFormat('yyyy-MM-dd').format(expirationDate);
  }
  
  /// Show an alert dialog for certificates that are about to expire
  void showExpirationAlerts(BuildContext context) {
    final expiringDomains = <String>[];
    
    for (final domain in _expirationDates.keys) {
      if (isCertificateAboutToExpire(domain)) {
        expiringDomains.add(domain);
      }
    }
    
    if (expiringDomains.isEmpty) {
      return; // No alerts needed
    }
    
    // Sort domains by expiration date (earliest first)
    expiringDomains.sort((a, b) => 
      _expirationDates[a]!.compareTo(_expirationDates[b]!));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate Expiration Alert'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following domains have certificates that will expire soon:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...expiringDomains.map((domain) {
                final expirationDate = _expirationDates[domain]!;
                final formattedDate = DateFormat('yyyy-MM-dd').format(expirationDate);
                final daysRemaining = getDaysUntilExpiration(domain) ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: daysRemaining < 7 ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$domain - Expires on $formattedDate (in $daysRemaining days)',
                          style: TextStyle(
                            color: daysRemaining < 7 ? Colors.red : Colors.black,
                            fontWeight: daysRemaining < 7 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text(
                'Please renew these certificates before they expire to avoid service disruptions.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              // Here you could navigate to a certificate management screen
              Navigator.of(context).pop();
              // Navigator.of(context).pushNamed('/certificate-management');
            },
            child: const Text('Manage Certificates'),
          ),
        ],
      ),
    );
  }
  
  /// Check all monitored domains for certificate expiration
  Future<void> checkAllDomains(List<String> domains) async {
    for (final domain in domains) {
      await checkCertificateExpiration(domain);
    }
  }
  
  /// Get all domains with their expiration status
  Map<String, Map<String, dynamic>> getAllCertificateStatus() {
    final Map<String, Map<String, dynamic>> status = {};
    
    for (final domain in _expirationDates.keys) {
      final expirationDate = _expirationDates[domain]!;
      final daysRemaining = getDaysUntilExpiration(domain) ?? 0;
      final isAboutToExpire = isCertificateAboutToExpire(domain);
      
      status[domain] = {
        'expirationDate': expirationDate,
        'formattedExpirationDate': DateFormat('yyyy-MM-dd').format(expirationDate),
        'daysRemaining': daysRemaining,
        'isAboutToExpire': isAboutToExpire,
        'status': isAboutToExpire ? 'warning' : 'ok',
      };
    }
    
    return status;
  }
  
  /// Check for expiring certificates and show alerts if needed
  /// This should be called during app initialization or periodically
  void checkAndNotify(BuildContext context, List<String> domains) async {
    await checkAllDomains(domains);
    
    // Only show notifications in debug or development mode
    assert(() {
      // Delay the notification slightly to allow the app to initialize
      Future.delayed(const Duration(seconds: 2), () {
        showExpirationAlerts(context);
      });
      return true;
    }());
  }
}