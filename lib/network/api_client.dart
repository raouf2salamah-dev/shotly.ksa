import 'package:dio/dio.dart'; 
import 'auth_interceptor.dart'; 
import 'token_repository.dart'; 
 
/// API Client that configures and builds a Dio instance with authentication
/// and other necessary interceptors for making API requests
class ApiClient { 
  /// Build a configured Dio instance with all required interceptors
  static Dio build() { 
    final dio = Dio(BaseOptions( 
      baseUrl: 'https://your.api.domain', // only HTTPS 
      connectTimeout: const Duration(seconds: 10), 
      receiveTimeout: const Duration(seconds: 15), 
    )); 

    dio.interceptors.add( 
      AuthInterceptor(dio: dio, tokens: TokenRepository()), 
    ); 

    // Optionally: add logging in debug builds 
    // dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true)); 

    return dio; 
  } 
}