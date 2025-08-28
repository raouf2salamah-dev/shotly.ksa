import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/encrypted_hive_service.dart';

class SecurityTestScreen extends StatefulWidget {
  const SecurityTestScreen({Key? key}) : super(key: key);

  @override
  State<SecurityTestScreen> createState() => _SecurityTestScreenState();
}

class _SecurityTestScreenState extends State<SecurityTestScreen> {
  String _secureStorageResult = 'No data';
  String _encryptedHiveResult = 'No data';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('SecureStorageService Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testSecureStorageWrite,
                    child: const Text('Write Token'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testSecureStorageRead,
                    child: const Text('Read Token'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Result: $_secureStorageResult'),
            const SizedBox(height: 24),
            const Text('EncryptedHiveService Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testEncryptedHiveWrite,
                    child: const Text('Write Data'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testEncryptedHiveRead,
                    child: const Text('Read Data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Result: $_encryptedHiveResult'),
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<void> _testSecureStorageWrite() async {
    setState(() => _isLoading = true);
    try {
      // Store a test token
      await SecureStorageService.write('test_token', 'secret_value_123');
      setState(() {
        _secureStorageResult = 'Token written successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _secureStorageResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSecureStorageRead() async {
    setState(() => _isLoading = true);
    try {
      // Read the test token
      final token = await SecureStorageService.read('test_token');
      setState(() {
        _secureStorageResult = 'Token: $token';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _secureStorageResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testEncryptedHiveWrite() async {
    setState(() => _isLoading = true);
    try {
      // Ensure EncryptedHiveService is initialized
      if (!EncryptedHiveService.initialized) {
        await EncryptedHiveService.initEarly();
      }
      
      // Store test data
      await EncryptedHiveService.save('test_key', {
        'sensitive_data': 'confidential_information_456',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      setState(() {
        _encryptedHiveResult = 'Data written successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _encryptedHiveResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testEncryptedHiveRead() async {
    setState(() => _isLoading = true);
    try {
      // Ensure EncryptedHiveService is initialized
      if (!EncryptedHiveService.initialized) {
        await EncryptedHiveService.initEarly();
      }
      
      // Read test data
      final data = EncryptedHiveService.get('test_key');
      
      setState(() {
        _encryptedHiveResult = 'Data: $data';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _encryptedHiveResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }
}