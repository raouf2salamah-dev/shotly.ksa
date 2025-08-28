import 'package:flutter/material.dart';
import '../../../bootstrap/security_bootstrap.dart';
import '../services/secure_http_client.dart';

/// Example of using SecureHttpClient with certificate pinning
class CertificatePinningExample extends StatefulWidget {
  const CertificatePinningExample({Key? key}) : super(key: key);

  @override
  State<CertificatePinningExample> createState() => _CertificatePinningExampleState();
}

class _CertificatePinningExampleState extends State<CertificatePinningExample> {
  final _urlController = TextEditingController(text: 'https://api.yourdomain.com');
  String _testResult = 'No test run yet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Set up a callback to handle certificate validation failures
    SecureHttpClient.onCertificateValidationFailure = (host, fingerprint) {
      // Show a user-friendly message when certificate validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Security alert: Invalid certificate detected for $host'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    };
  }

  Future<void> _testCertificatePinning() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing...';
    });

    try {
      // Use SecurityBootstrap.dio to test the certificate pinning implementation
      final dio = SecurityBootstrap.dio;
      final response = await dio.get(_urlController.text);
      
      final result = {
        'url': _urlController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'success': true,
        'status_code': response.statusCode,
        'certificate_validated': true,
        'message': 'Certificate validation successful'
      };
      
      setState(() {
        _testResult = 'Test Result:\n${_formatTestResult(result)}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTestResult(Map<String, dynamic> result) {
    return result.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Pinning Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Environment selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Environment',
                border: OutlineInputBorder(),
              ),
              value: 'production',
              items: const [
                DropdownMenuItem(value: 'production', child: Text('Production')),
                DropdownMenuItem(value: 'staging', child: Text('Staging')),
                DropdownMenuItem(value: 'development', child: Text('Development')),
              ],
              onChanged: (value) {
                if (value != null) {
                  SecureHttpClient.setEnvironment(value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // URL input
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL to test',
                border: OutlineInputBorder(),
                hintText: 'https://api.yourdomain.com',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            
            // Test button
            ElevatedButton(
              onPressed: _isLoading ? null : _testCertificatePinning,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Certificate Pinning'),
            ),
            const SizedBox(height: 16),
            
            // Results display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: SingleChildScrollView(
                  child: Text(_testResult),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}