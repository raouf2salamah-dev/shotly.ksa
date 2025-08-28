import 'package:flutter/material.dart';
import '../../../bootstrap/security_bootstrap.dart';

/// Example of managing certificate rotation with primary and backup certificates
class CertificateRotationExample extends StatefulWidget {
  const CertificateRotationExample({Key? key}) : super(key: key);

  @override
  State<CertificateRotationExample> createState() => _CertificateRotationExampleState();
}

class _CertificateRotationExampleState extends State<CertificateRotationExample> {
  final TextEditingController _domainController = TextEditingController(text: 'api.yourdomain.com');
  final TextEditingController _primaryFingerprintController = TextEditingController();
  final TextEditingController _backupFingerprintController = TextEditingController();
  final TextEditingController _rotationDateController = TextEditingController();
  
  String _statusMessage = 'No certificate rotation configured';
  bool _isRotationDueSoon = false;
  
  @override
  void initState() {
    super.initState();
    _checkRotationStatus();
  }
  
  void _checkRotationStatus() {
    final domain = _domainController.text;
    if (domain.isEmpty) return;
    
    final rotationDate = SecurityBootstrap.getCertificateRotationDate(domain);
    final isRotationDueSoon = SecurityBootstrap.isCertificateRotationDueSoon(domain);
    
    setState(() {
      if (rotationDate != null) {
        _statusMessage = 'Certificate rotation scheduled for $rotationDate';
        if (isRotationDueSoon) {
          _statusMessage += ' (Due soon!)';
        }
      } else {
        _statusMessage = 'No certificate rotation scheduled for $domain';
      }
      _isRotationDueSoon = isRotationDueSoon;
    });
  }
  
  void _configurePrimaryCertificate() {
    final domain = _domainController.text;
    final fingerprint = _primaryFingerprintController.text;
    final rotationDate = _rotationDateController.text.isNotEmpty ? _rotationDateController.text : null;
    
    if (domain.isEmpty || fingerprint.isEmpty) {
      _showSnackBar('Domain and primary fingerprint are required');
      return;
    }
    
    // Add the primary certificate fingerprint
    SecurityBootstrap.addCertificateFingerprint(
      domain,
      fingerprint,
      isPrimary: true,
      rotationDate: rotationDate,
    );
    
    _showSnackBar('Primary certificate configured for $domain');
    _checkRotationStatus();
  }
  
  void _configureBackupCertificate() {
    final domain = _domainController.text;
    final fingerprint = _backupFingerprintController.text;
    
    if (domain.isEmpty || fingerprint.isEmpty) {
      _showSnackBar('Domain and backup fingerprint are required');
      return;
    }
    
    // Add the backup certificate fingerprint
    SecurityBootstrap.addCertificateFingerprint(
      domain,
      fingerprint,
      isPrimary: false,
    );
    
    _showSnackBar('Backup certificate configured for $domain');
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Rotation Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Certificate Rotation Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Domain input
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(
                labelText: 'API Domain',
                hintText: 'api.yourdomain.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Primary certificate section
            const Text(
              'Primary Certificate (Current)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _primaryFingerprintController,
              decoration: const InputDecoration(
                labelText: 'Primary Certificate Fingerprint (SHA-256)',
                hintText: 'AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rotationDateController,
              decoration: const InputDecoration(
                labelText: 'Rotation Date (YYYY-MM-DD)',
                hintText: '2024-12-31',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _configurePrimaryCertificate,
              child: const Text('Configure Primary Certificate'),
            ),
            const SizedBox(height: 16),
            
            // Backup certificate section
            const Text(
              'Backup Certificate (For Rotation)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _backupFingerprintController,
              decoration: const InputDecoration(
                labelText: 'Backup Certificate Fingerprint (SHA-256)',
                hintText: '5E:8F:16:52:78:84:DF:09:C0:3E:34:7D:9E:B6:1A:DF:5E:3B:7F:A6:0D:48:4A:C1:3D:B2:0E:79:56:E5:5A:44',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _configureBackupCertificate,
              child: const Text('Configure Backup Certificate'),
            ),
            const SizedBox(height: 24),
            
            // Status section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isRotationDueSoon ? Colors.amber.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isRotationDueSoon ? Colors.amber : Colors.grey,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificate Rotation Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isRotationDueSoon ? Colors.amber.shade800 : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_statusMessage),
                  if (_isRotationDueSoon) ...[  
                    const SizedBox(height: 8),
                    const Text(
                      'Action required: Update your app with the new certificate before the rotation date!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Check status button
            ElevatedButton(
              onPressed: _checkRotationStatus,
              child: const Text('Check Rotation Status'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _domainController.dispose();
    _primaryFingerprintController.dispose();
    _backupFingerprintController.dispose();
    _rotationDateController.dispose();
    super.dispose();
  }
}