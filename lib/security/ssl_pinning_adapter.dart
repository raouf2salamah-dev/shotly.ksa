import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'certificate_pinning_service.dart';

/// DioPinning provides certificate pinning functionality using CertificatePinningService
/// 
/// This implementation configures Dio with certificate pinning using the centralized service.
class DioPinning {
  /// Build a Dio instance with SSL certificate pinning configured
  /// 
  /// Returns a configured Dio instance with certificate pinning enabled
  static Dio build() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://your.api.domain',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    CertificatePinningService().configureDio(dio);

    return dio;
  }
  
  /// Build a Dio instance with SSL certificate pinning and custom base URL
  /// 
  /// [baseUrl] The base URL for API requests
  /// [connectTimeout] Connection timeout in seconds
  /// [receiveTimeout] Receive timeout in seconds
  /// 
  /// Returns a configured Dio instance with certificate pinning enabled
  static Dio buildWithCustomConfig({
    required String baseUrl,
    int connectTimeout = 10,
    int receiveTimeout = 15,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: connectTimeout),
      receiveTimeout: Duration(seconds: receiveTimeout),
    ));

    CertificatePinningService().configureDio(dio);

    return dio;
  }
}