import 'package:dio/dio.dart';
import '../security/secure_storage.dart';
import '../../bootstrap/security_bootstrap.dart';

/// SignedApiService provides API request functionality with HMAC-SHA256 request signing
/// for secure client-server communication.
/// 
/// This service automatically signs requests using a device-specific signing key
/// that should be created server-side during device registration.
class SignedApiService {
  final Dio _dio;
  
  /// Create a new SignedApiService with the provided Dio instance
  /// If no Dio instance is provided, uses the SecurityBootstrap.dio instance
  SignedApiService({Dio? dio}) : _dio = dio ?? SecurityBootstrap.dio;
  
  /// Initialize the service with base URL and other options
  void initialize({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
  }) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout;
    
    // Add interceptor for automatic request signing
    _dio.interceptors.add(_createSigningInterceptor());
  }
  
  /// Create an interceptor that signs all outgoing requests
  Interceptor _createSigningInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final path = options.path;
        final body = options.data?.toString() ?? '';
        
        // Add timestamp header
        options.headers['X-Timestamp'] = timestamp;
        
        // Sign the request
        final signature = await SecureStorageService.signRequest(path, body, timestamp);
        if (signature != null) {
          options.headers['X-Signature'] = signature;
        }
        
        return handler.next(options);
      },
    );
  }
  
  /// Make a GET request to the specified path
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  /// Make a POST request to the specified path with the provided data
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
  
  /// Make a PUT request to the specified path with the provided data
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }
  
  /// Make a DELETE request to the specified path
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
  
  /// Store a device signing key received from the server
  /// This should be called after successful device registration
  Future<void> storeDeviceSigningKey(String signingKey) {
    return SecureStorageService.storeDeviceSigningKey(signingKey);
  }
  
  /// Check if a device signing key is available
  Future<bool> hasDeviceSigningKey() async {
    final key = await SecureStorageService.getDeviceSigningKey();
    return key != null;
  }
}