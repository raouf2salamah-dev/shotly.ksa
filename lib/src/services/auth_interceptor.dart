import 'package:dio/dio.dart';
import '../security/secure_storage.dart';

/// AuthInterceptor for Dio HTTP client that handles authentication tokens
/// including automatic token refresh when receiving 401 Unauthorized responses
class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _refreshing = false;
  
  /// Create a new AuthInterceptor with a reference to the Dio instance
  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.read('access_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_refreshing) {
      _refreshing = true;
      try {
        final newToken = await _refresh();
        _refreshing = false;
        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final cloneReq = await dio.fetch(opts);
          return handler.resolve(cloneReq);
        }
      } catch (_) {}
    }
    handler.next(err);
  }

  /// Refresh the access token using the refresh token
  /// 
  /// Returns the new access token if successful, null otherwise
  Future<String?> _refresh() async {
    final rtoken = await SecureStorageService.read('refresh_token');
    if (rtoken == null) return null;
    
    final res = await dio.post('/auth/refresh', data: {'refresh_token': rtoken});
    final newAccess = res.data['access_token'];
    final newRefresh = res.data['refresh_token'];
    
    if (newAccess != null) {
      await SecureStorageService.write('access_token', newAccess);
      if (newRefresh != null) await SecureStorageService.write('refresh_token', newRefresh);
    }
    
    return newAccess;
  }
}