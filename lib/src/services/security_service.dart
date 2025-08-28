import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'sensitive_data_manager.dart';
import '../utils/logger.dart';
import '../widgets/security_features_dialog.dart';
import '../widgets/security_intro_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Security settings configuration class
class SecuritySettings {
  /// Timeout in minutes before showing lock screen after app goes to background
  final int timeoutMinutes;
  
  /// Whether biometric authentication is required for unlocking
  final bool requireBiometrics;
  
  /// Constructor with default values
  SecuritySettings({this.timeoutMinutes = 5, this.requireBiometrics = true});
}

/// A service that handles security features like screenshot detection and protection
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  
  /// Singleton instance
  factory SecurityService() => _instance;
  
  SecurityService._internal() {
    // Initialize logger
    _logger = Logger('SecurityService');
  }
  
  /// Logger instance
  late final Logger _logger;
  
  /// Security settings configuration
  SecuritySettings securitySettings = SecuritySettings();
  
  /// Method channel for native communication
  static const MethodChannel _channel = MethodChannel('com.shotly.app/screenshot');
  
  /// Callback to be executed when a screenshot is detected
  VoidCallback? onScreenshotDetected;
  
  /// Sensitive data manager for handling data protection during app lifecycle changes
  late final SensitiveDataManager _sensitiveDataManager;
  
  /// Initialize the security service
  Future<void> initialize() async {
    // Set up method call handler for screenshot detection
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Enable secure screen on Android
    if (!kIsWeb && Platform.isAndroid) {
      await enableSecureScreen();
    }
    
    /// Initialize sensitive data manager
    _sensitiveDataManager = SensitiveDataManager(
      securityService: this,
      onClearSensitiveData: null, // Set this to a callback if needed
      onShowLockScreen: null, // Set this to a callback if needed
    );
    _sensitiveDataManager.init();
    
    _logger.i('Initialized with timeout: ${securitySettings.timeoutMinutes} minutes');
  }
  
  /// Update security settings
  void updateSecuritySettings(SecuritySettings settings) {
    securitySettings = settings;
    _logger.i('Updated settings - timeout: ${settings.timeoutMinutes} minutes, biometrics: ${settings.requireBiometrics}');
  }
  
  /// Check if biometric authentication is required
  bool requiresBiometricAuth() {
    return securitySettings.requireBiometrics;
  }
  
  /// Set a callback to clear sensitive data when app enters background
  void setSensitiveDataCallback(VoidCallback callback) {
    _sensitiveDataManager = SensitiveDataManager(
      securityService: this,
      onClearSensitiveData: callback,
      onShowLockScreen: _sensitiveDataManager.onShowLockScreen,
    );
    _sensitiveDataManager.init();
  }
  
  /// Set a callback to show lock screen after inactivity timeout
  void setLockScreenCallback(VoidCallback callback) {
    _sensitiveDataManager = SensitiveDataManager(
      securityService: this,
      onClearSensitiveData: _sensitiveDataManager.onClearSensitiveData,
      onShowLockScreen: callback,
    );
    _sensitiveDataManager.init();
  }
  
  /// Enable secure screen to prevent screenshots and screen recordings on Android
  Future<void> enableSecureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        _logger.i('Secure screen enabled');
      } catch (e) {
        _logger.e('Failed to enable secure screen', error: e);
      }
    }
  }
  
  /// Disable secure screen to allow screenshots and screen recordings on Android
  Future<void> disableSecureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        _logger.i('Secure screen disabled');
      } catch (e) {
        _logger.e('Failed to disable secure screen', error: e);
      }
    }
  }
  
  /// Handle method calls from the native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScreenshot':
        _handleScreenshotDetected();
        return null;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }
  
  /// Handle screenshot detection
  void _handleScreenshotDetected() {
    _logger.w('Screenshot detected!');
    
    // Call the callback if it's set
    if (onScreenshotDetected != null) {
      onScreenshotDetected!();
    }
  }
  
  /// Check if the current platform supports screenshot detection
  bool get supportsScreenshotDetection {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }
  
  /// Check if the current platform supports screenshot prevention
  bool get supportsScreenshotPrevention {
    if (kIsWeb) return false;
    // Only Android supports FLAG_SECURE for preventing screenshots
    return Platform.isAndroid;
  }
  
  /// Check if the current platform supports app switcher content hiding
  bool get supportsAppSwitcherHiding {
    if (kIsWeb) return false;
    // iOS supports secure text entry and blur overlay techniques
    return Platform.isIOS;
  }
  
  /// Apply content protection for sensitive content (images/videos)
  /// This marks the content as sensitive so the native overlay will be shown
  /// when the app enters the background or app switcher
  /// 
  /// If isProtected is true, the content will be hidden with an AnimatedOpacity
  Widget applyContentProtection(Widget child, {bool isProtected = false}) {
    // Apply AnimatedOpacity for hiding content when protection is active
    final contentWidget = AnimatedOpacity(
      opacity: isProtected ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
    
    if (!kIsWeb && Platform.isIOS) {
      // Use VisibilityDetector to track when sensitive content becomes visible or hidden
      return VisibilityDetector(
        key: const Key('sensitive_content_detector'),
        onVisibilityChanged: (info) {
          // When visibility changes significantly, update the protection status
          if (info.visibleFraction > 0.1) {
            // Content is visible, enable protection
            setupIOSAppSwitcherProtection();
          } else {
            // Content is hidden, disable protection
            disableIOSAppSwitcherProtection();
          }
        },
        child: contentWidget,
      );
    }
    return contentWidget;
  }
  
  /// Setup native iOS app switcher protection for sensitive content
  /// This enables a single opaque black overlay when app enters background
  Future<void> setupIOSAppSwitcherProtection() async {
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _channel.invokeMethod('setupAppSwitcherProtection');
        _logger.i('iOS app switcher protection setup');
      } catch (e) {
        _logger.e('Failed to setup iOS app switcher protection', error: e);
      }
    }
  }
  
  /// Setup iOS app switcher protection with error handling
  /// This method throws specific errors that can be caught and handled
  Future<void> setupIOSAppSwitcherProtectionWithErrorHandling() async {
    if (kIsWeb || !Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('enableOverlayProtection');
      _logger.i('iOS app switcher protection enabled with error handling');
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'OVERLAY_ALREADY_ADDED':
          _logger.w('Overlay already exists. No action needed.');
          throw Exception('OverlayError.alreadyAdded');
        case 'OVERLAY_FAILED_TO_ADD':
          _logger.e('Failed to add overlay. Check memory and view hierarchy.', error: e);
          throw Exception('OverlayError.failedToAdd');
        default:
          _logger.e('Unexpected error', error: e);
          throw Exception(e.message);
      }
    }
  }
  
  /// Enables a black overlay when the app goes into the background.
  /// This prevents sensitive content from appearing in the app switcher.
  ///
  /// Throws an exception if the overlay fails to initialize or is already added.
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await securityService.enableOverlayProtection();
  /// } catch (e) {
  ///   print(e.toString());
  /// }
  /// ```
  Future<void> enableOverlayProtection() async {
    if (kIsWeb || !Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('enableOverlayProtection');
      _logger.i('Overlay protection enabled');
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'OVERLAY_ALREADY_ADDED':
          _logger.w('Overlay already exists. No action needed.');
          throw Exception('OverlayError.alreadyAdded');
        case 'OVERLAY_FAILED_TO_ADD':
          _logger.e('Failed to add overlay. Check memory and view hierarchy.', error: e);
          throw Exception('OverlayError.failedToAdd');
        default:
          _logger.e('Unexpected error', error: e);
          throw Exception(e.message);
      }
    }
  }
  
  /// Disable native iOS app switcher protection when no sensitive content is visible
  Future<void> disableIOSAppSwitcherProtection() async {
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _channel.invokeMethod('disableAppSwitcherProtection');
        _logger.i('iOS app switcher protection disabled');
      } catch (e) {
        _logger.e('Failed to disable iOS app switcher protection', error: e);
      }
    }
  }
  
  /// Set a callback to be executed when a screenshot is detected
  void setScreenshotCallback(VoidCallback callback) {
    onScreenshotDetected = callback;
  }
  
  /// Shows a dialog explaining the security features to the user
  void showSecurityIntro(BuildContext context) { 
    showDialog( 
      context: context, 
      builder: (context) => AlertDialog( 
        title: const Text("Content Protection Enabled"), 
        content: const Text( 
            "For your security, screenshots and unauthorized access are blocked. " 
            "Sensitive content is also hidden when the app goes to the background."), 
        actions: [ 
          TextButton( 
            child: const Text("Got it"), 
            onPressed: () => Navigator.of(context).pop(), 
          ), 
        ], 
      ), 
    ); 
  }
  
  /// Shows the new security features dialog to inform users about the latest security enhancements
  /// Returns true if the dialog was shown, false otherwise
  Future<bool> showNewSecurityFeaturesDialog(BuildContext context) async {
    // Use the dialog widget to show the new security features
    // This needs to be imported at the top of the file
    return await SecurityFeaturesDialog.showIfNeeded(context);
  }
  
  /// Check if security dialog has been shown before and show it if not
  /// Returns true if the dialog was shown, false otherwise
  Future<bool> checkAndShowSecurityDialog(BuildContext context) async { 
    final prefs = await SharedPreferences.getInstance(); 
    final shown = prefs.getBool('security_dialog_shown') ?? false; 
 
    if (!shown) { 
      await showDialog( 
        context: context, 
        builder: (_) => const SecurityIntroDialog(), 
      ); 
      await prefs.setBool('security_dialog_shown', true); 
      return true;
    } 
    return false;
  }
}