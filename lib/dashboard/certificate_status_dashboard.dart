import 'package:flutter/material.dart';
import '../security/certificate_expiration_service.dart';
import '../security/certificate_pinning_service.dart';
import '../bootstrap/security_bootstrap.dart';
import 'package:intl/intl.dart';

/// A dashboard component that displays certificate status information
/// including expiration dates, primary and backup fingerprints, and last rotation dates.
class CertificateStatusDashboard extends StatefulWidget {
  const CertificateStatusDashboard({Key? key}) : super(key: key);

  @override
  State<CertificateStatusDashboard> createState() => _CertificateStatusDashboardState();
}

class _CertificateStatusDashboardState extends State<CertificateStatusDashboard> {
  final CertificateExpirationService _expirationService = CertificateExpirationService();
  final CertificatePinningService _pinningService = CertificatePinningService();
  
  bool _isLoading = true;
  List<String> _domains = [];
  Map<String, Map<String, dynamic>> _certificateStatus = {};
  
  @override
  void initState() {
    super.initState();
    _loadCertificateData();
  }
  
  Future<void> _loadCertificateData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Get all domains with certificate pinning
    _domains = _pinningService.getAllDomains();
    
    // Check certificate expiration for all domains
    await _expirationService.checkAllDomains(_domains);
    
    // Get certificate status
    _certificateStatus = _expirationService.getAllCertificateStatus();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Certificate Status Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      'Alert Threshold: ${_expirationService.getAlertThreshold()} days',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      onPressed: _loadCertificateData,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCertificateTable(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCertificateTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Domain')),
          DataColumn(label: Text('Expiration Date')),
          DataColumn(label: Text('Days Remaining')),
          DataColumn(label: Text('Primary Fingerprint')),
          DataColumn(label: Text('Backup Fingerprint')),
          DataColumn(label: Text('Last Rotation Date')),
          DataColumn(label: Text('Status')),
        ],
        rows: _domains.map((domain) {
          final status = _certificateStatus[domain];
          final daysRemaining = status?['daysRemaining'] ?? 0;
          final expirationDate = status?['formattedExpirationDate'] ?? 'Unknown';
          final isAboutToExpire = status?['isAboutToExpire'] ?? false;
          
          // Get fingerprints
          final primaryFingerprint = _pinningService.getPrimaryFingerprint(domain) ?? 'Not configured';
          final backupFingerprint = _pinningService.getBackupFingerprint(domain) ?? 'Not configured';
          
          // Get rotation date
          final rotationDateStr = SecurityBootstrap.getCertificateRotationDate(domain);
          String formattedRotationDate = 'Not set';
          
          if (rotationDateStr != null) {
            try {
              final rotationDate = DateTime.parse(rotationDateStr);
              formattedRotationDate = DateFormat('yyyy-MM-dd').format(rotationDate);
            } catch (e) {
              formattedRotationDate = 'Invalid date';
            }
          }
          
          return DataRow(
            cells: [
              DataCell(Text(domain)),
              DataCell(Text(expirationDate)),
              DataCell(
                Text(
                  '$daysRemaining days',
                  style: TextStyle(
                    color: daysRemaining <= 30
                        ? Colors.red
                        : daysRemaining <= 60
                            ? Colors.orange
                            : Colors.green,
                    fontWeight: daysRemaining <= 30 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              DataCell(_buildFingerprintCell(primaryFingerprint)),
              DataCell(_buildFingerprintCell(backupFingerprint)),
              DataCell(Text(formattedRotationDate)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAboutToExpire ? Icons.warning_amber_rounded : Icons.check_circle,
                      color: isAboutToExpire ? Colors.orange : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAboutToExpire ? 'Expiring Soon' : 'Valid',
                      style: TextStyle(
                        color: isAboutToExpire ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildFingerprintCell(String fingerprint) {
    // Truncate fingerprint for display
    final displayFingerprint = fingerprint.length > 16
        ? '${fingerprint.substring(0, 8)}...${fingerprint.substring(fingerprint.length - 8)}'
        : fingerprint;
    
    return Tooltip(
      message: fingerprint,
      child: Text(displayFingerprint),
    );
  }
}