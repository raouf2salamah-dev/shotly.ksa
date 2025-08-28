import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'logger.dart';
import 'package:meta/meta.dart';

/// A utility class to help with Firebase Crashlytics reporting
class CrashlyticsHelper {
  /// Logger instance for this class
  static final _logger = Logger('CrashlyticsHelper');
  static bool isTestMode = false;
  /// Check if Crashlytics is supported on the current platform
  static bool get isCrashlyticsSupported => !kIsWeb;
  
  static FirebaseCrashlytics? _instance;

  @visibleForTesting
  static set instance(FirebaseCrashlytics value) {
    debugPrint('Setting Crashlytics instance to ${value.runtimeType}. Stack trace:\n${StackTrace.current}');
    _instance = value;
  }
  
  @visibleForTesting
  static void resetInstance() {
    debugPrint('Resetting Crashlytics instance. Stack trace:\n${StackTrace.current}');
    _instance = null;
  }

  static FirebaseCrashlytics get instance {
    print('Crashlytics getter called. Stack trace:\n${StackTrace.current}');
    if (_instance == null) {
      print('Initializing real Crashlytics instance. Stack trace:\n${StackTrace.current}');
      _instance = FirebaseCrashlytics.instance;
    } else {
      print('Returning existing instance of type: ${_instance.runtimeType}');
    }
    return _instance!;
  }
  
  /// Initialize Crashlytics
  static Future<void> initialize() async {
    if (!isCrashlyticsSupported || isTestMode) {
      _logger.i('Crashlytics initialize (web fallback): Crashlytics not supported on web');
      return;
    }
    
    try {
      // Set Crashlytics collection enabled
      await instance.setCrashlyticsCollectionEnabled(true);
      
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = instance.recordFlutterFatalError;
      
      // Log initialization
      await log('Crashlytics initialized');
    } catch (e) {
      _logger.e('Error initializing Crashlytics', error: e);
    }
  }

  /// Log a message to Crashlytics
  static Future<void> log(String message) async {
    if (!isCrashlyticsSupported || isTestMode) {
      _logger.d('Crashlytics log (web fallback): $message');
      return;
    }
    
    debugPrint('CrashlyticsHelper.log using instance: ${instance.runtimeType}');
    
    try {
      await instance.log(message);
    } catch (e) {
      _logger.e('Error logging to Crashlytics', error: e);
    }
  }

  /// Record a non-fatal error to Crashlytics
  static Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason}) async {
    if (!isCrashlyticsSupported || isTestMode) {
      _logger.e('Crashlytics recordError (web fallback)', error: exception);
      if (reason != null) _logger.i('Reason: $reason');
      return;
    }
    
    try {
      await instance.recordError(
        exception,
        stack,
        reason: reason,
      );
    } catch (e) {
      _logger.e('Error recording error to Crashlytics', error: e);
    }
  }

  /// Set a custom key to help with debugging
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (!isCrashlyticsSupported || isTestMode) {
      _logger.d('Crashlytics setCustomKey (web fallback): $key = $value');
      return;
    }
    
    debugPrint('CrashlyticsHelper.setCustomKey using instance: ${instance.runtimeType}');
    
    try {
      await instance.setCustomKey(key, value);
    } catch (e) {
      _logger.e('Error setting custom key in Crashlytics', error: e);
    }
  }

  /// Set user identifier to track issues by user
  static Future<void> setUserIdentifier(String identifier) async {
    print('In setUserIdentifier: kIsWeb = $kIsWeb, isCrashlyticsSupported = $isCrashlyticsSupported, isTestMode = $isTestMode');
    print('Condition: (!isCrashlyticsSupported || isTestMode) = ${!isCrashlyticsSupported || isTestMode}');
    if (!isCrashlyticsSupported || isTestMode) {
      _logger.d('Crashlytics setUserIdentifier (web fallback): $identifier');
      return;
    }
    
    print('CrashlyticsHelper.setUserIdentifier using instance: ${instance.runtimeType}');
    
    try {
      await instance.setUserIdentifier(identifier);
    } catch (e) {
      _logger.e('Error setting user identifier in Crashlytics', error: e);
    }
  }
}