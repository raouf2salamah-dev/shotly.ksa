import 'package:flutter/material.dart';
import '../bootstrap/security_bootstrap.dart';
import '../ui/security_intro.dart';
import '../security/secure_storage.dart';
import '../security/device_integrity.dart';
import '../security/certificate_pinning_service.dart';
import '../network/auth_interceptor.dart';
import '../network/request_signer.dart';
import 'package:dio/dio.dart';

/// Example widget demonstrating how to use the security features
class SecurityFeaturesExample extends StatefulWidget {
  const SecurityFeaturesExample({Key? key}) : super(key: key);

  @override
  State<SecurityFeaturesExample> createState() => _SecurityFeaturesExampleState();
}

class _SecurityFeaturesExampleState extends State<SecurityFeaturesExample> {
  final _dio = Dio();
  bool _isLoading = false;
  String _statusMessage = 'Security features not initialized';
  Map<String, dynamic> _securityReport = {};

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing security features...';
    });

    try {
      // Initialize security bootstrap
      await SecurityBootstrap.initialize(
        dio: _dio,
        validateCertificates: true,
        checkDeviceIntegrity: true,
      );

      // Get security report
      final report = await SecurityBootstrap.getSecurityReport();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Security features initialized successfully';
        _securityReport = report;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error initializing security features: $e';
      });
    }
  }

  Future<void> _testSecureStorage() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing secure storage...';
    });

    try {
      // Store a test value
      await SecureStorage.write('test_key', 'test_value');
      
      // Read the test value
      final value = await SecureStorage.read('test_key');
      
      // Delete the test value
      await SecureStorage.delete('test_key');
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Secure storage test successful: $value';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Secure storage test failed: $e';
      });
    }
  }

  Future<void> _testRequestSigning() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing request signing...';
    });

    try {
      // Generate a test signature
      final signature = await RequestSigner.signRequest(
        path: '/api/test',
        body: '{"test":true}',
      );
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Request signing test successful: $signature';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Request signing test failed: $e';
      });
    }
  }

  Future<void> _testDeviceIntegrity() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing device integrity...';
    });

    try {
      // Check device integrity
      final report = await DeviceIntegrity.getIntegrityReport();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Device integrity test successful';
        _securityReport['device_integrity'] = report;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Device integrity test failed: $e';
      });
    }
  }

  void _showSecurityIntro() {
    SecurityIntro.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Features Example'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(_statusMessage),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Report',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          _buildSecurityReportItem(
                            'Device Integrity',
                            !(_securityReport['device_integrity']?['is_compromised'] ?? true),
                          ),
                          _buildSecurityReportItem(
                            'Certificate Pinning',
                            _securityReport['certificate_pinning_enabled'] ?? false,
                          ),
                          _buildSecurityReportItem(
                            'Request Signing',
                            _securityReport['has_signing_key'] ?? false,
                          ),
                          _buildSecurityReportItem(
                            'Authentication',
                            _securityReport['has_access_token'] ?? false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _testSecureStorage,
                    child: const Text('Test Secure Storage'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testRequestSigning,
                    child: const Text('Test Request Signing'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testDeviceIntegrity,
                    child: const Text('Test Device Integrity'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showSecurityIntro,
                    child: const Text('Show Security Intro Dialog'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityReportItem(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.error,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
}