import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/crashlytics_helper.dart';
import '../utils/logger.dart';

/// A service to track user actions and events using Firebase Analytics
class AnalyticsService {
  /// Logger instance for this class
  final _logger = Logger('AnalyticsService');
  late final FirebaseAnalytics? _analytics;
  
  // Constructor with initialization
  AnalyticsService._internal() {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      _logger.e('Failed to initialize Firebase Analytics', error: e);
      _analytics = null;
    }
  }
  
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  
  factory AnalyticsService() {
    return _instance;
  }

  /// Initialize analytics service
  Future<void> init() async {
    try {
      // Check if Firebase Analytics is available
      if (_analytics == null) {
        _logger.w('Firebase Analytics instance is null, skipping initialization');
        return;
      }
      
      // Enable analytics collection
      await _analytics?.setAnalyticsCollectionEnabled(true);
      
      // Log initialization
      await CrashlyticsHelper.log('Analytics service initialized');
    } catch (e) {
      _logger.e('Error initializing analytics service', error: e);
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error initializing analytics service'
      );
    }
  }

  /// Log a login event
  Future<void> logLogin({required String method}) async {
    try {
      if (_analytics == null) {
        _logger.w('Analytics is null, skipping login logging');
        return;
      }
      await _analytics!.logLogin(loginMethod: method);
      _logger.i('Logged login with method: $method');
    } catch (e) {
      _logger.e('Error logging login', error: e);
    }
  }
  
  /// Log a content view event
  Future<void> logContentView({
    required String contentId,
    required String contentTitle,
    required String contentType,
    String? sellerId,
  }) async {
    try {
      if (_analytics == null) {
        _logger.w('Analytics is null, skipping content view logging');
        return;
      }
      await _analytics!.logEvent(
        name: 'content_view',
        parameters: {
          'content_id': contentId,
          'content_title': contentTitle,
          'content_type': contentType,
          'seller_id': sellerId ?? '',
        },
      );
      _logger.i('Logged content view for $contentId');
    } catch (e) {
      _logger.e('Error logging content view', error: e);
    }
  }

  /// Log a favorite action (add or remove)
  Future<void> logFavoriteAction({
    required String contentId,
    required String contentTitle,
    required bool isFavorited,
  }) async {
    try {
      await _analytics?.logEvent(
        name: isFavorited ? 'add_to_favorites' : 'remove_from_favorites',
        parameters: {
          'content_id': contentId,
          'content_title': contentTitle,
        },
      );
      _logger.i('Logged ${isFavorited ? "add to" : "remove from"} favorites for $contentId');
    } catch (e) {
      _logger.e('Error logging favorite action', error: e);
    }
  }

  /// Log a search event
  Future<void> logSearch({
    required String searchTerm,
    String? contentType,
    String? category,
  }) async {
    try {
      await _analytics?.logSearch(
        searchTerm: searchTerm,
        parameters: {
          'content_type': contentType ?? 'all',
          'category': category ?? 'all',
        },
      );
      _logger.i('Logged search for "$searchTerm"');
    } catch (e) {
      _logger.e('Error logging search', error: e);
    }
  }

  /// Log a purchase event
  Future<void> logPurchase({
    required String contentId,
    required String contentTitle,
    required double price,
    required String currency,
    required String sellerId,
  }) async {
    try {
      await _analytics?.logPurchase(
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: contentId,
            itemName: contentTitle,
            price: price,
          ),
        ],
        parameters: {
          'seller_id': sellerId,
        },
      );
      _logger.i('Logged purchase for $contentId');
    } catch (e) {
      _logger.e('Error logging purchase', error: e);
    }
  }

  /// Log a download event
  Future<void> logDownload({
    required String contentId,
    required String contentTitle,
    required String contentType,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'content_download',
        parameters: {
          'content_id': contentId,
          'content_title': contentTitle,
          'content_type': contentType,
        },
      );
      _logger.i('Logged download for $contentId');
    } catch (e) {
      _logger.e('Error logging download', error: e);
    }
  }

  /// Log a share event
  Future<void> logShare({
    required String contentId,
    required String contentTitle,
    required String contentType,
    required String method,
  }) async {
    try {
      await _analytics?.logShare(
        contentType: contentType,
        itemId: contentId,
        method: method,
      );
      _logger.i('Logged share for $contentId via $method');
    } catch (e) {
      _logger.e('Error logging share', error: e);
    }
  }

  /// Log a user login event with additional parameters
  Future<void> logUserLogin({
    required String method,
  }) async {
    try {
      await _analytics?.logLogin(
        loginMethod: method,
      );
      _logger.i('Logged login via $method');
    } catch (e) {
      _logger.e('Error logging login', error: e);
    }
  }

  /// Log a user registration event
  Future<void> logSignUp({
    required String method,
  }) async {
    try {
      await _analytics?.logSignUp(
        signUpMethod: method,
      );
      _logger.i('Logged sign up via $method');
    } catch (e) {
      _logger.e('Error logging sign up', error: e);
    }
  }

  /// Set user properties for better analytics segmentation
  Future<void> setUserProperties({
    required String userId,
    String? userRole,
  }) async {
    try {
      await _analytics?.setUserId(id: userId);
      
      if (userRole != null) {
        await _analytics?.setUserProperty(
          name: 'user_role',
          value: userRole,
        );
      }
      
      _logger.i('Set user properties for $userId');
    } catch (e) {
      _logger.e('Error setting user properties', error: e);
    }
  }
}