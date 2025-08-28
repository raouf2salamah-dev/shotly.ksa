import 'package:flutter/material.dart';
import '../services/signed_api_service.dart';
import '../security/secure_storage.dart';
import 'package:dio/dio.dart';

/// Example screen demonstrating the usage of SignedApiService with HMAC-SHA256 request signing
class SignedApiExample extends StatefulWidget {
  const SignedApiExample({Key? key}) : super(key: key);

  @override
  _SignedApiExampleState createState() => _SignedApiExampleState();
}

class _SignedApiExampleState extends State<SignedApiExample> {
  final TextEditingController _signingKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController(text: 'https://api.example.com');
  final TextEditingController _requestPathController = TextEditingController(text: '/protected-resource');
  final TextEditingController _requestBodyController = TextEditingController(text: '{"example": "data"}');
  
  late SignedApiService _apiService;
  String _responseText = 'No API calls made yet';
  bool _isLoading = false;
  bool _hasSigningKey = false;

  @override
  void initState() {
    super.initState();
    _setupApiService();
    _checkSigningKey();
  }

  void _setupApiService() {
    _apiService = SignedApiService();
    _apiService.initialize(baseUrl: _apiUrlController.text);
  }

  Future<void> _checkSigningKey() async {
    setState(() => _isLoading = true);
    
    try {
      final hasKey = await _apiService.hasDeviceSigningKey();
      final key = await SecureStorageService.getDeviceSigningKey();
      
      setState(() {
        _hasSigningKey = hasKey;
        if (key != null) _signingKeyController.text = key;
      });
    } catch (e) {
      _showSnackBar('Error checking signing key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSigningKey() async {
    if (_signingKeyController.text.isEmpty) {
      _showSnackBar('Please enter a signing key');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _apiService.storeDeviceSigningKey(_signingKeyController.text);
      await _checkSigningKey();
      _showSnackBar('Signing key saved successfully');
    } catch (e) {
      _showSnackBar('Error saving signing key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearSigningKey() async {
    setState(() => _isLoading = true);
    
    try {
      await SecureStorageService.delete('device_signing_key');
      await _checkSigningKey();
      setState(() {
        _signingKeyController.clear();
      });
      _showSnackBar('Signing key cleared successfully');
    } catch (e) {
      _showSnackBar('Error clearing signing key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeSignedRequest() async {
    if (!_hasSigningKey) {
      _showSnackBar('Please set a signing key first');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _responseText = 'Making signed request...';
    });
    
    try {
      // Update base URL in case it was changed
      _apiService.initialize(baseUrl: _apiUrlController.text);
      
      // Make a signed request
      final path = _requestPathController.text;
      final body = _requestBodyController.text;
      
      // For demonstration, we'll use POST, but the service supports all methods
      final response = await _apiService.post(path, data: body);
      
      setState(() {
        _responseText = 'Response: ${response.statusCode}\n${response.data}';
      });
    } catch (e) {
      setState(() {
        if (e is DioError) {
          _responseText = 'Error: ${e.response?.statusCode}\n${e.response?.data ?? e.message}';
        } else {
          _responseText = 'Error: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
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
        title: const Text('Signed API Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSecurityWarning(),
            const SizedBox(height: 16),
            const Text(
              'Device Signing Key',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This key should be created server-side during device registration.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _signingKeyController,
              decoration: InputDecoration(
                labelText: 'Signing Key',
                border: const OutlineInputBorder(),
                suffixIcon: _hasSigningKey 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.warning, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSigningKey,
                    child: const Text('Save Signing Key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _clearSigningKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Clear Signing Key'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'API Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _requestPathController,
              decoration: const InputDecoration(
                labelText: 'Request Path',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _requestBodyController,
              decoration: const InputDecoration(
                labelText: 'Request Body (JSON)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _makeSignedRequest,
              child: const Text('Make Signed Request'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Response:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_responseText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '⚠️ Security Warning',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'While this example uses secure storage for the signing key, client-side secrets '
            'may still be extractable on rooted/jailbroken devices or through sophisticated attacks. '
            'Never rely solely on client-side security for protecting highly sensitive information.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _signingKeyController.dispose();
    _apiUrlController.dispose();
    _requestPathController.dispose();
    _requestBodyController.dispose();
    super.dispose();
  }
}