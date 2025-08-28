import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:developer' as developer;

class AnalyticsServiceSafe {
  // Use Flutter's built-in logging instead of logger package
  void _log(String message, {Object? error}) {
    developer.log(message, error: error);
  }
  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;

  // Singleton pattern
  static final AnalyticsServiceSafe _instance = AnalyticsServiceSafe._internal();
  factory AnalyticsServiceSafe() => _instance;

  AnalyticsServiceSafe._internal() {
    _initializeAnalytics();
  }

  void _initializeAnalytics() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      _log('Analytics service initialized successfully');
    } catch (e) {
      _log('Failed to initialize Analytics service', error: e);
      _isInitialized = false;
    }
  }

  /// Log a login event
  Future<void> logLogin({required String method}) async {
    if (!_isInitialized || _analytics == null) {
      _log('Analytics not initialized, skipping login logging');
      return;
    }

    try {
      await _analytics!.logLogin(loginMethod: method);
      _log('Logged login with method: $method');
    } catch (e) {
      _log('Error logging login', error: e);
    }
  }

  /// Log a content view event
  Future<void> logContentView({
    required String contentId,
    required String contentTitle,
    required String contentType,
    String? sellerId,
  }) async {
    if (!_isInitialized || _analytics == null) {
      _log('Analytics not initialized, skipping content view logging');
      return;
    }

    try {
      await _analytics!.logEvent(
        name: 'content_view',
        parameters: {
          'content_id': contentId,
          'content_title': contentTitle,
          'content_type': contentType,
          'seller_id': sellerId ?? '',
        },
      );
      _log('Logged content view for $contentId');
    } catch (e) {
      _log('Error logging content view', error: e);
    }
  }
}