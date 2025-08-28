import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../bootstrap/security_bootstrap.dart';
import '../services/auth_interceptor.dart';
import '../security/secure_storage.dart';

/// Example screen demonstrating the usage of AuthInterceptor with Dio
class AuthInterceptorExample extends StatefulWidget {
  const AuthInterceptorExample({Key? key}) : super(key: key);

  @override
  _AuthInterceptorExampleState createState() => _AuthInterceptorExampleState();
}

class _AuthInterceptorExampleState extends State<AuthInterceptorExample> {
  final TextEditingController _accessTokenController = TextEditingController();
  final TextEditingController _refreshTokenController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController(text: 'https://api.example.com');
  
  late Dio _dio;
  String _responseText = 'No API calls made yet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _loadTokens();
  }

  void _setupDio() {
    // Use SecurityBootstrap.dio which already has certificate pinning and other security features
    _dio = SecurityBootstrap.buildPinnedDio(
      baseUrl: _apiUrlController.text,
      connectTimeout: 5000, // milliseconds
      receiveTimeout: 3000, // milliseconds
    );
    
    // AuthInterceptor is already added in SecurityBootstrap.buildPinnedDio
  }

  Future<void> _loadTokens() async {
    setState(() => _isLoading = true);
    
    try {
      final accessToken = await SecureStorageService.read('access_token');
      final refreshToken = await SecureStorageService.read('refresh_token');
      
      setState(() {
        if (accessToken != null) _accessTokenController.text = accessToken;
        if (refreshToken != null) _refreshTokenController.text = refreshToken;
      });
    } catch (e) {
      _showSnackBar('Error loading tokens: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTokens() async {
    setState(() => _isLoading = true);
    
    try {
      await SecureStorageService.write('access_token', _accessTokenController.text);
      await SecureStorageService.write('refresh_token', _refreshTokenController.text);
      _showSnackBar('Tokens saved successfully');
    } catch (e) {
      _showSnackBar('Error saving tokens: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearTokens() async {
    setState(() => _isLoading = true);
    
    try {
      await SecureStorageService.delete('access_token');
      await SecureStorageService.delete('refresh_token');
      setState(() {
        _accessTokenController.clear();
        _refreshTokenController.clear();
      });
      _showSnackBar('Tokens cleared successfully');
    } catch (e) {
      _showSnackBar('Error clearing tokens: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeAuthenticatedRequest() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Making authenticated request...';
    });
    
    try {
      // Update base URL in case it was changed
      _dio.options.baseUrl = _apiUrlController.text;
      
      // Make an authenticated request - the interceptor will add the token
      final response = await _dio.get('/protected-resource');
      
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
        title: const Text('Auth Interceptor Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Token Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accessTokenController,
              decoration: const InputDecoration(
                labelText: 'Access Token',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _refreshTokenController,
              decoration: const InputDecoration(
                labelText: 'Refresh Token',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTokens,
                    child: const Text('Save Tokens'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _clearTokens,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Clear Tokens'),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _makeAuthenticatedRequest,
              child: const Text('Make Authenticated Request'),
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

  @override
  void dispose() {
    _accessTokenController.dispose();
    _refreshTokenController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }
}