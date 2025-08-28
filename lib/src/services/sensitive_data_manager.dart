import 'package:flutter/widgets.dart';
import 'security_service.dart';
import '../utils/logger.dart';

/// A manager class that handles sensitive data protection during app lifecycle changes
/// 
/// This class uses WidgetsBindingObserver to detect when the app enters background
/// and automatically clears sensitive data from memory to prevent data leakage.
/// 
/// It integrates with SecurityService to ensure both UI protection (via app switcher
/// protection) and data protection are handled consistently.
class SensitiveDataManager with WidgetsBindingObserver {
  /// Logger instance for this class
  final _logger = Logger('SensitiveDataManager');
  /// The security service instance to coordinate with
  final SecurityService _securityService;
  
  /// Callback to clear sensitive data when app enters background
  final VoidCallback? onClearSensitiveData;
  
  /// Callback to show lock screen after inactivity timeout
  final VoidCallback? onShowLockScreen;
  
  /// Timestamp when the app went to background
  DateTime? _backgroundTime;
  
  /// Constructor that takes a security service instance and optional callbacks
  SensitiveDataManager({
    required SecurityService securityService,
    this.onClearSensitiveData,
    this.onShowLockScreen,
  }) : _securityService = securityService;
  
  /// Initialize the manager and register for app lifecycle events
  void init() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  /// Dispose the manager and unregister from app lifecycle events
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is entering background, clear sensitive data
      clearSensitiveData();
      
      // Record the time when app went to background
      _backgroundTime = DateTime.now();
      
      // Ensure app switcher protection is enabled on iOS
      if (_securityService.supportsAppSwitcherHiding) {
        _securityService.setupIOSAppSwitcherProtectionWithErrorHandling();
        _logger.d('App switcher protection requested when entering background');
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground
      // Check if app was in background for more than the configured timeout
      if (_backgroundTime != null && 
          DateTime.now().difference(_backgroundTime!).inMinutes >= _securityService.securitySettings.timeoutMinutes) {
        // Show lock screen or require re-authentication
        showLockScreen();
      }
      
      // Reset background time
      _backgroundTime = null;
      
      // No need to disable app switcher protection here as it's handled
      // by the native code when app becomes active again
    }
  }
  
  /// Clear sensitive data from memory
  /// 
  /// This method should clear any sensitive information stored in memory,
  /// such as text controllers, cached images, or temporary storage.
  void clearSensitiveData() {
    // Call the provided callback if available
    if (onClearSensitiveData != null) {
      onClearSensitiveData!();
    }
    
    // Add default clearing behavior here if needed
    // Example:
    // - Clear text controllers
    // - Clear cached images
    // - Clear temporary storage
  }
  
  /// Show lock screen after inactivity timeout
  /// 
  /// This method is called when the app has been in the background
  /// for more than the specified timeout period in SecuritySettings.
  void showLockScreen() {
    // Call the provided callback if available
    if (onShowLockScreen != null) {
      onShowLockScreen!();
    }
    
    // Log whether biometric authentication is required
    _logger.i('Lock screen shown. Biometric auth required: ${_securityService.requiresBiometricAuth()}');
    
    // If no callback is provided, implement default behavior
    // This could be handled by the security service in a real implementation
  }
}