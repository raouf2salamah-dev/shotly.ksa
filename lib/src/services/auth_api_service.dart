import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../bootstrap/security_bootstrap.dart';
import 'token_service.dart';

/// AuthApiService handles authentication API requests with token management
class AuthApiService {
  // Base API URL - replace with your actual API endpoint
  static const String _baseUrl = 'https://api.example.com';
  
  /// Login with username and password
  /// 
  /// Returns true if login successful
  static Future<bool> login(String username, String password) async {
    try {
      final dio = SecurityBootstrap.dio;
      final response = await dio.post(
        '$_baseUrl/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store tokens with their expiration times
        await TokenService.storeAccessToken(
          data['access_token'],
          expiresIn: Duration(seconds: data['expires_in'] ?? 900), // Default 15 minutes
        );
        
        await TokenService.storeRefreshToken(
          data['refresh_token'],
          expiresIn: Duration(days: data['refresh_expires_in'] ?? 7), // Default 7 days
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }
  
  /// Refresh access token using refresh token
  /// 
  /// Returns true if refresh successful
  static Future<bool> refreshAccessToken() async {
    try {
      // Get refresh token
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('No valid refresh token found');
        return false;
      }
      
      final dio = SecurityBootstrap.dio;
      final response = await dio.post(
        '$_baseUrl/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store new access token
        await TokenService.storeAccessToken(
          data['access_token'],
          expiresIn: Duration(seconds: data['expires_in'] ?? 900),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }
  
  /// Logout - revoke tokens on server and clear locally
  // Fix missing ) in logout post call
  static Future<bool> logout() async {
    try {
      // Get access token
      final accessToken = await TokenService.getAccessToken();
      if (accessToken != null) {
        // Revoke token on server
        final dio = SecurityBootstrap.dio;
        await dio.post(
          '$_baseUrl/auth/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          ),
        );
      }
      
      // Clear tokens locally regardless of server response
      await TokenService.clearTokens();
      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear tokens locally even if server request fails
      await TokenService.clearTokens();
      return true;
    }
  }
  
  /// Make authenticated API request
  /// 
  /// Automatically handles token refresh if access token expired
  static Future<Response?> authenticatedRequest(
    String method,
    String endpoint,
    {Map<String, dynamic>? body}
  ) async {
    try {
      // Get access token
      String? accessToken = await TokenService.getAccessToken();
      
      // If no valid access token, try to refresh
      if (accessToken == null) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          debugPrint('Failed to refresh access token');
          return null;
        }
        
        // Get new access token after refresh
        accessToken = await TokenService.getAccessToken();
        if (accessToken == null) {
          debugPrint('Still no valid access token after refresh');
          return null;
        }
      }
      
      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      
      // Make request based on method
      final dio = SecurityBootstrap.dio;
      Response response;
      final url = '$_baseUrl$endpoint';
      
      final options = Options(headers: headers);
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await dio.get(url, options: options);
          break;
        case 'POST':
          response = await dio.post(
            url,
            data: body,
            options: options,
          );
          break;
        case 'PUT':
          response = await dio.put(
            url,
            data: body,
            options: options,
          );
          break;
        case 'DELETE':
          response = await dio.delete(url, options: options);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      // Handle 401 Unauthorized - token might be expired or invalid
      if (response.statusCode == 401) {
        // Try to refresh token
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          debugPrint('Failed to refresh token after 401');
          return null;
        }
        
        // Get new access token
        accessToken = await TokenService.getAccessToken();
        if (accessToken == null) {
          debugPrint('Still no valid access token after refresh');
          return null;
        }
        
        // Update authorization header
        headers['Authorization'] = 'Bearer $accessToken';
        
        // Update options with new token
        options.headers = headers;
        
        // Retry the request
        switch (method.toUpperCase()) {
          case 'GET':
            response = await dio.get(url, options: options);
            break;
          case 'POST':
            response = await dio.post(
              url,
              data: body,
              options: options,
            );
            break;
          case 'PUT':
            response = await dio.put(
              url,
              data: body,
              options: options,
            );
            break;
          case 'DELETE':
            response = await dio.delete(url, options: options);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }
      }
      
      return response;
    } catch (e) {
      debugPrint('Authenticated request error: $e');
      return null;
    }
  }
}