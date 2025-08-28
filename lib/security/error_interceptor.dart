import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Intercepts Dio errors and displays user-friendly messages
/// Particularly useful for handling certificate pinning failures
class ErrorInterceptor extends Interceptor {
  final BuildContext context;

  ErrorInterceptor(this.context);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'Something went wrong. Please try again.';

    if (err.type == DioExceptionType.badCertificate) {
      message = 'Secure connection could not be verified. '
          'Please check your internet or update the app.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please try again later.';
    } else if (err.response?.statusCode == 401) {
      message = 'Your session has expired. Please log in again.';
    }

    // show a small banner or snackbar instead of crashing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    super.onError(err, handler);
  }
}