import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// This script simulates an expired token scenario to test the token refresh mechanism
/// 
/// It creates a mock server that:
/// 1. Returns 401 on the first request with a valid token (simulating expiration)
/// 2. Allows token refresh
/// 3. Accepts the request with the new token
void main() async {
  // Create a mock server
  final mockServer = MockServer();
  await mockServer.start();
  
  print('🔧 Mock server started on port ${mockServer.port}');
  
  // Create a client with auth interceptor
  final client = createClientWithAuthInterceptor('http://localhost:${mockServer.port}');
  
  // Store initial tokens
  await storeInitialTokens();
  
  print('🔑 Initial tokens stored');
  print('📝 Access token: mock_access_token');
  print('📝 Refresh token: mock_refresh_token');
  
  // Make a request that will trigger the 401 -> refresh -> retry flow
  try {
    print('\n🚀 Making initial request (will receive 401)...');
    final response = await client.get('/protected-resource');
    print('✅ Request succeeded after token refresh!');
    print('📄 Response: ${response.data}');
  } catch (e) {
    print('❌ Request failed: $e');
  }
  
  // Cleanup
  await mockServer.stop();
  print('\n🧹 Mock server stopped');
}

/// Creates a Dio client with auth interceptor
Dio createClientWithAuthInterceptor(String baseUrl) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  
  // Add interceptor for handling auth
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('🔒 Adding token to request...');
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          print('⚠️ Received 401 Unauthorized, attempting to refresh token...');
          
          try {
            // Get refresh token
            final refreshToken = await getRefreshToken();
            if (refreshToken == null) {
              print('❌ No refresh token available');
              return handler.next(error);
            }
            
            // Attempt to refresh the token
            final dio = Dio();
            final refreshResponse = await dio.post(
              '${error.requestOptions.baseUrl}/auth/refresh',
              data: {'refresh_token': refreshToken},
            );
            
            if (refreshResponse.statusCode == 200) {
              print('✅ Token refresh successful');
              
              // Store the new tokens
              final newAccessToken = refreshResponse.data['access_token'];
              final newRefreshToken = refreshResponse.data['refresh_token'];
              
              await storeTokens(newAccessToken, newRefreshToken);
              print('🔑 New tokens stored');
              print('📝 New access token: $newAccessToken');
              
              // Retry the original request with the new token
              print('🔄 Retrying original request with new token...');
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';
              
              final response = await dio.fetch(options);
              return handler.resolve(response);
            }
          } catch (e) {
            print('❌ Token refresh failed: $e');
          }
        }
        
        return handler.next(error);
      },
    ),
  );
  
  return dio;
}

/// Mock server implementation
class MockServer {
  final port = 8080;
  HttpServer? _server;
  bool _firstRequest = true;
  
  Future<void> start() async {
    _server = await HttpServer.bind('localhost', port);
    
    _server!.listen((request) async {
      print('\n📨 Received ${request.method} request to ${request.uri.path}');
      
      // Enable CORS
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', '*');
      
      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }
      
      // Handle refresh token endpoint
      if (request.uri.path == '/auth/refresh' && request.method == 'POST') {
        await _handleRefreshToken(request);
        return;
      }
      
      // Handle protected resource
      if (request.uri.path == '/protected-resource') {
        await _handleProtectedResource(request);
        return;
      }
      
      // Default 404 response
      request.response.statusCode = 404;
      request.response.write(jsonEncode({'error': 'Not found'}));
      await request.response.close();
    });
  }
  
  Future<void> _handleRefreshToken(HttpRequest request) async {
    // Read request body
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body);
    
    if (data['refresh_token'] == 'mock_refresh_token') {
      print('✅ Valid refresh token received');
      
      // Return new tokens
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'access_token': 'new_mock_access_token',
        'refresh_token': 'new_mock_refresh_token',
        'expires_in': 3600
      }));
    } else {
      print('❌ Invalid refresh token');
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'error': 'Invalid refresh token'}));
    }
    
    await request.response.close();
  }
  
  Future<void> _handleProtectedResource(HttpRequest request) async {
    final authHeader = request.headers.value('authorization');
    
    if (authHeader == null) {
      print('❌ No Authorization header');
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'error': 'No Authorization header'}));
      await request.response.close();
      return;
    }
    
    final token = authHeader.replaceFirst('Bearer ', '');
    
    // First request with the original token will fail with 401
    if (_firstRequest && token == 'mock_access_token') {
      print('⚠️ Simulating expired token (returning 401)');
      _firstRequest = false;
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'error': 'Token expired'}));
    } 
    // Subsequent request with new token will succeed
    else if (token == 'new_mock_access_token') {
      print('✅ Valid new token received');
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'message': 'Protected resource accessed successfully',
        'data': {'id': 123, 'name': 'Sensitive Data'}
      }));
    } else {
      print('❌ Invalid token: $token');
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'error': 'Invalid token'}));
    }
    
    await request.response.close();
  }
  
  Future<void> stop() async {
    await _server?.close();
  }
}

/// Mock secure storage functions
Map<String, String> _secureStorage = {};

Future<void> storeInitialTokens() async {
  await storeTokens('mock_access_token', 'mock_refresh_token');
}

Future<void> storeTokens(String accessToken, String refreshToken) async {
  _secureStorage['access_token'] = accessToken;
  _secureStorage['refresh_token'] = refreshToken;
}

Future<String?> getAccessToken() async {
  return _secureStorage['access_token'];
}

Future<String?> getRefreshToken() async {
  return _secureStorage['refresh_token'];
}