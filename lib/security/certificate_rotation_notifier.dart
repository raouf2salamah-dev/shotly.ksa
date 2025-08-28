import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bootstrap/security_bootstrap.dart';

/// A service that monitors certificate rotation dates and provides notifications
/// when certificates are due for rotation.
class CertificateRotationNotifier {
  /// Singleton instance
  static final CertificateRotationNotifier _instance = CertificateRotationNotifier._internal();
  
  /// Factory constructor to return the singleton instance
  factory CertificateRotationNotifier() => _instance;
  
  /// Private constructor for singleton pattern
  CertificateRotationNotifier._internal();
  
  /// List of domains to monitor for certificate rotation
  final List<String> _monitoredDomains = [];
  
  /// Add a domain to monitor for certificate rotation
  void addDomainToMonitor(String domain) {
    if (!_monitoredDomains.contains(domain)) {
      _monitoredDomains.add(domain);
    }
  }
  
  /// Remove a domain from monitoring
  void removeDomainFromMonitor(String domain) {
    _monitoredDomains.remove(domain);
  }
  
  /// Check if any monitored domains have certificates due for rotation soon
  /// Returns a map of domains to their rotation dates for those due soon
  Map<String, DateTime> getDomainsWithPendingRotation() {
    final Map<String, DateTime> pendingRotations = {};
    
    for (final domain in _monitoredDomains) {
      if (SecurityBootstrap.isCertificateRotationDueSoon(domain)) {
        final rotationDateStr = SecurityBootstrap.getCertificateRotationDate(domain);
        if (rotationDateStr != null) {
          // Convert the string date to DateTime object
          try {
            final rotationDate = DateTime.parse(rotationDateStr);
            pendingRotations[domain] = rotationDate;
          } catch (e) {
            // If date parsing fails, use a default date 14 days from now
            pendingRotations[domain] = DateTime.now().add(const Duration(days: 14));
          }
        }
      }
    }
    
    return pendingRotations;
  }
  
  /// Show a notification dialog for certificates due for rotation
  void showRotationNotifications(BuildContext context) {
    final pendingRotations = getDomainsWithPendingRotation();
    
    if (pendingRotations.isEmpty) {
      return; // No notifications needed
    }
    
    // Sort domains by rotation date (earliest first)
    final sortedDomains = pendingRotations.keys.toList()
      ..sort((a, b) => pendingRotations[a]!.compareTo(pendingRotations[b]!));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate Rotation Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following domains have certificates that need rotation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...sortedDomains.map((domain) {
                final rotationDate = pendingRotations[domain]!;
                final formattedDate = DateFormat('yyyy-MM-dd').format(rotationDate);
                final daysRemaining = rotationDate.difference(DateTime.now()).inDays;
                
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
                          '$domain - Rotation due on $formattedDate (in $daysRemaining days)',
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
                'Please ensure that both primary and backup certificates are properly configured before the rotation date.',
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
  
  /// Check for pending rotations and show notifications if needed
  /// This should be called during app initialization or periodically
  void checkAndNotify(BuildContext context) {
    // Only show notifications in debug or development mode
    assert(() {
      // Delay the notification slightly to allow the app to initialize
      Future.delayed(const Duration(seconds: 2), () {
        showRotationNotifications(context);
      });
      return true;
    }());
  }
}