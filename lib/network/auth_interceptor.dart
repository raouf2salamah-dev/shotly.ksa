import 'package:dio/dio.dart'; 
import 'token_repository.dart'; 
 
/// Adds Authorization header + handles token refresh 
class AuthInterceptor extends Interceptor { 
  final Dio dio; 
  final TokenRepository tokens; 
 
  AuthInterceptor({required this.dio, required this.tokens}); 
 
  @override 
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async { 
    final access = await tokens.readAccessToken(); 
    if (access != null) { 
      options.headers['Authorization'] = 'Bearer $access'; 
    } 
    // ensure HTTPS 
    if (!options.uri.scheme.startsWith('https')) { 
      return handler.reject( 
        DioException( 
          requestOptions: options, 
          error: 'Insecure HTTP calls are not allowed', 
          type: DioExceptionType.badResponse, 
        ), 
      ); 
    } 
    handler.next(options); 
  } 
 
  @override 
  void onError(DioException err, ErrorInterceptorHandler handler) async { 
    // if 401 → try refresh 
    if (err.response?.statusCode == 401) { 
      final refreshed = await _refreshToken(); 
      if (refreshed) { 
        final retryReq = await _retry(err.requestOptions); 
        return handler.resolve(retryReq); 
      } 
    } 
    handler.next(err); 
  } 
 
  Future<bool> _refreshToken() async { 
    final refresh = await tokens.readRefreshToken(); 
    if (refresh == null) return false; 
 
    try { 
      final resp = await dio.post('/auth/refresh', data: {'refresh_token': refresh}); 
      final newAccess = resp.data['access_token']; 
      final newRefresh = resp.data['refresh_token']; 
      await tokens.saveTokens(access: newAccess, refresh: newRefresh); 
      return true; 
    } catch (_) { 
      return false; 
    } 
  } 
 
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async { 
    final newOptions = Options( 
      method: requestOptions.method, 
      headers: requestOptions.headers, 
    ); 
    return dio.request<dynamic>( 
      requestOptions.path, 
      data: requestOptions.data, 
      queryParameters: requestOptions.queryParameters, 
      options: newOptions, 
    ); 
  }
  
  /// Check if the path is an authentication endpoint
  bool _isAuthEndpoint(String path) {
    final authPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/login',
      '/register',
      '/refresh',
    ];
    
    return authPaths.any((authPath) => path.endsWith(authPath));
  }
}