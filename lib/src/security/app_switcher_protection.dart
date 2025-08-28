import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A class that provides app switcher protection functionality for iOS.
/// 
/// This class communicates with the native iOS code to add a black overlay
/// when the app enters the app switcher, preventing sensitive content from
/// being visible in the app switcher preview.
class AppSwitcherProtection {
  static const MethodChannel _channel = MethodChannel('com.shotly.app/screenshot');
  static final AppSwitcherProtection _instance = AppSwitcherProtection._internal();
  
  /// Factory constructor that returns the singleton instance
  factory AppSwitcherProtection() => _instance;
  
  /// Private constructor for singleton pattern
  AppSwitcherProtection._internal();
  
  /// Whether the current platform supports app switcher protection
  bool get isSupported => !kIsWeb && Platform.isIOS;
  
  /// Enable app switcher protection
  /// 
  /// This will add a black overlay when the app enters the app switcher
  /// Returns true if successful, false otherwise
  Future<bool> enableProtection() async {
    if (!isSupported) return false;
    
    try {
      await _channel.invokeMethod('setupAppSwitcherProtection');
      return true;
    } catch (e) {
      debugPrint('Failed to enable app switcher protection: $e');
      return false;
    }
  }
  
  /// Disable app switcher protection
  /// 
  /// This will remove the black overlay when the app enters the app switcher
  /// Returns true if successful, false otherwise
  Future<bool> disableProtection() async {
    if (!isSupported) return false;
    
    try {
      await _channel.invokeMethod('disableAppSwitcherProtection');
      return true;
    } catch (e) {
      debugPrint('Failed to disable app switcher protection: $e');
      return false;
    }
  }
  
  /// Enable app switcher protection with error handling
  /// 
  /// This will add a black overlay when the app enters the app switcher
  /// Throws exceptions with specific error codes that can be caught and handled
  Future<void> enableProtectionWithErrorHandling() async {
    if (!isSupported) return;
    
    try {
      await _channel.invokeMethod('enableOverlayProtection');
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'OVERLAY_ALREADY_ADDED':
          throw Exception('OverlayError.alreadyAdded');
        case 'OVERLAY_FAILED_TO_ADD':
          throw Exception('OverlayError.failedToAdd');
        default:
          throw Exception(e.message);
      }
    }
  }
}