import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, kReleaseMode;
import '../utils/crashlytics_helper.dart';

/// Enum defining different log levels
enum LogLevel {
  /// Debug level for detailed information (development only)
  debug,
  
  /// Info level for general information
  info,
  
  /// Warning level for potential issues
  warning,
  
  /// Error level for runtime errors
  error,
  
  /// Critical level for severe errors that might crash the app
  critical
}

/// A utility class for logging with different levels and sensitive data protection
class Logger {
  /// Tag for identifying the source of the log
  final String tag;
  
  /// Minimum log level to display
  static LogLevel _minLogLevel = LogLevel.debug;
  
  /// Whether to send logs to Crashlytics
  static bool _sendToCrashlytics = true;
  
  /// Constructor that takes a tag for identifying the log source
  Logger(this.tag);
  
  /// Set the minimum log level to display
  static void setMinLogLevel(LogLevel level) {
    _minLogLevel = level;
  }
  
  /// Enable or disable sending logs to Crashlytics
  static void setSendToCrashlytics(bool send) {
    _sendToCrashlytics = send;
  }
  
  /// Log a debug message
  /// Only logs in debug mode, suppressed in production
  void d(String message) {
    // In production mode, debug logs are suppressed
    if (kReleaseMode) return;
    _log(LogLevel.debug, message);
  }
  
  /// Log an info message
  void i(String message) {
    _log(LogLevel.info, message);
  }
  
  /// Log a warning message
  void w(String message) {
    _log(LogLevel.warning, message);
  }
  
  /// Log an error message
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }
  
  /// Conditional logging that behaves differently in debug vs. production
  /// 
  /// In debug mode: Logs the debug message with full details
  /// In production mode: Logs the production message with minimal info
  /// 
  /// Example:
  /// ```dart
  /// logger.conditional(
  ///   debugMessage: "Debug: overlay added successfully",
  ///   productionMessage: "Overlay protection initialized"
  /// );
  /// ```
  void conditional({
    required String debugMessage,
    required String productionMessage,
    LogLevel debugLevel = LogLevel.debug,
    LogLevel productionLevel = LogLevel.info,
  }) {
    if (kDebugMode) {
      _log(debugLevel, debugMessage);
    } else {
      _log(productionLevel, productionMessage);
    }
  }
  
  /// Log a critical error message
  void c(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, error: error, stackTrace: stackTrace);
  }
  
  /// Internal method to handle logging based on level
  void _log(LogLevel level, String message, {dynamic error, StackTrace? stackTrace}) {
    // Skip if below minimum log level
    if (level.index < _minLogLevel.index) {
      return;
    }
    
    final String levelStr = level.toString().split('.').last.toUpperCase();
    final String logMessage = '[$levelStr] $tag: $message';
    
    // Different logging behavior based on build mode
    if (kDebugMode) {
      // Debug build: Verbose logging with emojis and details
      switch (level) {
        case LogLevel.debug:
          debugPrint(logMessage);
          break;
        case LogLevel.info:
          debugPrint(logMessage);
          break;
        case LogLevel.warning:
          debugPrint('⚠️ $logMessage');
          break;
        case LogLevel.error:
          debugPrint('🔴 $logMessage');
          if (error != null) {
            debugPrint('Error details: $error');
          }
          break;
        case LogLevel.critical:
          debugPrint('🆘 $logMessage');
          if (error != null) {
            debugPrint('Critical error details: $error');
          }
          break;
      }
    } else {
      // Production build: Minimal logging, only important levels
      // Skip debug logs entirely in production
      if (level == LogLevel.debug) return;
      
      // For other levels, use more concise logging
      switch (level) {
        case LogLevel.debug:
          // Already handled above
          break;
        case LogLevel.info:
          // Only log essential info in production
          debugPrint(logMessage);
          break;
        case LogLevel.warning:
        case LogLevel.error:
        case LogLevel.critical:
          // Always log warnings, errors and critical issues
          debugPrint(logMessage);
          break;
      }
    }
    
    // Send to Crashlytics for warning and above if enabled
    if (_sendToCrashlytics && level.index >= LogLevel.warning.index) {
      _sendToCrashlyticsIfAvailable(level, logMessage, error, stackTrace);
    }
  }
  
  /// Send log to Crashlytics if available
  Future<void> _sendToCrashlyticsIfAvailable(
    LogLevel level,
    String message,
    dynamic error,
    StackTrace? stackTrace
  ) async {
    if (!CrashlyticsHelper.isCrashlyticsSupported) {
      return;
    }
    
    try {
      // Log the message
      await CrashlyticsHelper.log(message);
      
      // Record error for error and critical levels
      if (level == LogLevel.error || level == LogLevel.critical) {
        final errorToReport = error ?? message;
        final stackTraceToReport = stackTrace ?? StackTrace.current;
        
        await CrashlyticsHelper.recordError(
          errorToReport,
          stackTraceToReport,
          reason: level == LogLevel.critical ? 'CRITICAL: $message' : message,
        );
      }
    } catch (e) {
      // Fallback to debug print if Crashlytics fails
      debugPrint('Failed to send to Crashlytics: $e');
    }
  }
  
  /// Safely log potentially sensitive data by redacting it
  void logSensitive(LogLevel level, String message, {required Map<String, dynamic> sensitiveData}) {
    final redactedMessage = _redactSensitiveData(message, sensitiveData);
    _log(level, redactedMessage);
  }
  
  /// Redact sensitive data from log messages
  String _redactSensitiveData(String message, Map<String, dynamic> sensitiveData) {
    String redactedMessage = message;
    
    sensitiveData.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        // Replace the actual value with a redacted placeholder
        final String redactedValue = _getRedactedValue(value);
        redactedMessage = redactedMessage.replaceAll(value.toString(), redactedValue);
      }
    });
    
    return redactedMessage;
  }
  
  /// Get a redacted value based on the type of data
  String _getRedactedValue(dynamic value) {
    if (value is String) {
      if (_isEmailAddress(value)) {
        return _redactEmail(value);
      } else if (_isPhoneNumber(value)) {
        return _redactPhoneNumber(value);
      } else if (_isCreditCard(value)) {
        return _redactCreditCard(value);
      } else if (value.length > 4) {
        // For other strings, show first and last character with asterisks in between
        return '${value[0]}${'*' * (value.length - 2)}${value[value.length - 1]}';
      }
    }
    
    // Default redaction for other types
    return '***REDACTED***';
  }
  
  /// Check if a string is an email address
  bool _isEmailAddress(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value);
  }
  
  /// Redact an email address
  String _redactEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***REDACTED_EMAIL***';
    
    final username = parts[0];
    final domain = parts[1];
    
    String redactedUsername;
    if (username.length <= 2) {
      redactedUsername = '*' * username.length;
    } else {
      redactedUsername = '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    }
    
    return '$redactedUsername@$domain';
  }
  
  /// Check if a string is a phone number
  bool _isPhoneNumber(String value) {
    final phoneRegex = RegExp(r'^\+?[0-9\-\s\(\)]{8,}$');
    return phoneRegex.hasMatch(value);
  }
  
  /// Redact a phone number
  String _redactPhoneNumber(String phone) {
    // Keep last 4 digits, redact the rest
    if (phone.length <= 4) return '***REDACTED_PHONE***';
    
    final lastFourDigits = phone.substring(phone.length - 4);
    return '${'*' * (phone.length - 4)}$lastFourDigits';
  }
  
  /// Check if a string is a credit card number
  bool _isCreditCard(String value) {
    // Remove spaces and dashes
    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it's a 13-19 digit number
    final creditCardRegex = RegExp(r'^[0-9]{13,19}$');
    return creditCardRegex.hasMatch(cleanValue);
  }
  
  /// Redact a credit card number
  String _redactCreditCard(String cardNumber) {
    // Keep last 4 digits, redact the rest
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (cleanNumber.length <= 4) return '***REDACTED_CARD***';
    
    final lastFourDigits = cleanNumber.substring(cleanNumber.length - 4);
    return '****-****-****-$lastFourDigits';
  }
}