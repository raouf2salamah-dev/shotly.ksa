import 'package:flutter/material.dart';
import 'dart:collection';
import '../services/secure_storage_service.dart';
import 'dart:async';

/// Manages security-related dialogs and their display frequency
class SecurityDialogManager {
  /// Default key used to store dialog display status in SharedPreferences
  static const String _securityDialogShownKey = 'security_dialog_shown';
  
  /// Set to track dialogs shown in the current session
  static final HashSet<String> _dialogsShownInSession = HashSet<String>();
  
  /// Shows the security introduction dialog if it hasn't been shown before
  /// 
  /// Returns true if the dialog was shown, false if it was already shown before
  static Future<bool> showSecurityIntroDialogIfNeeded({
    required BuildContext context,
    required Widget Function() dialogBuilder,
  }) async {
    return showDialogIfNeeded(
      context,
      _securityDialogShownKey,
      dialogBuilder,
    );
  }
  
  /// Shows a dialog if it hasn't been shown before based on the provided key
  /// 
  /// Parameters:
  /// - context: The BuildContext to show the dialog
  /// - dialogKey: The unique key to track if this specific dialog has been shown
  /// - dialogBuilder: Function that returns the dialog widget to show
  /// 
  /// Returns true if the dialog was shown, false if it was already shown before
  static Future<bool> showDialogIfNeeded(
    BuildContext context,
    String dialogKey,
    Widget Function() dialogBuilder,
  ) async {
    // Check if the dialog has been shown before using secure storage
    final dialogShown = await SecureStorageService.read(dialogKey);
    
    if (dialogShown != 'true') {
      if (context.mounted) {
        // Use a microtask to defer dialog creation until after the current frame
        // This improves performance by not blocking the UI thread
        await Future.microtask(() async {
          if (context.mounted) {
            // Show the dialog
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => dialogBuilder(),
            );
          }
        });
        
        // Mark the dialog as shown using secure storage
        await SecureStorageService.write(dialogKey, 'true');
      }
      return true;
    }
    
    return false;
  }
  
  /// Resets the shown status of the security dialog
  /// 
  /// This can be useful for testing or when you want to show the dialog again
  /// after a major security update
  static Future<void> resetSecurityDialogShownStatus() async {
    await SecureStorageService.write(_securityDialogShownKey, 'false');
  }
  
  /// Resets the shown status of a specific dialog by key
  /// 
  /// Parameters:
  /// - dialogKey: The unique key of the dialog to reset
  static Future<void> resetDialogShownStatus(String dialogKey) async {
    await SecureStorageService.write(dialogKey, 'false');
  }
  
  /// Checks if the security dialog has been shown before
  static Future<bool> hasSecurityDialogBeenShown() async {
    final value = await SecureStorageService.read(_securityDialogShownKey);
    return value == 'true';
  }
  
  /// Checks if a specific dialog has been shown before
  /// 
  /// Parameters:
  /// - dialogKey: The unique key of the dialog to check
  static Future<bool> hasDialogBeenShown(String dialogKey) async {
    final value = await SecureStorageService.read(dialogKey);
    return value == 'true';
  }
  
  /// Shows a dialog for a sensitive screen if it hasn't been shown in the current session
  /// 
  /// Parameters:
  /// - context: The BuildContext to show the dialog
  /// - screenKey: The unique key identifying the sensitive screen
  /// - dialogBuilder: Function that returns the dialog widget to show
  /// 
  /// Returns true if the dialog was shown, false if it was already shown in this session
  static Future<bool> showSensitiveScreenDialogInSession(
    BuildContext context,
    String screenKey,
    Widget Function() dialogBuilder,
  ) async {
    // Check if the dialog has been shown in this session
    if (!_dialogsShownInSession.contains(screenKey)) {
      if (context.mounted) {
        // Use a microtask to defer dialog creation until after the current frame
        // This improves performance by not blocking the UI thread
        await Future.microtask(() async {
          if (context.mounted) {
            // Show the dialog
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => dialogBuilder(),
            );
          }
        });
        
        // Mark the dialog as shown in this session
        _dialogsShownInSession.add(screenKey);
      }
      return true;
    }
    
    return false;
  }
  
  /// Resets all session-based dialog tracking
  /// 
  /// This can be useful when logging out or when you want to show all sensitive screen
  /// dialogs again in a new session
  static void resetSessionDialogs() {
    _dialogsShownInSession.clear();
  }
  
  /// Checks if a sensitive screen dialog has been shown in the current session
  /// 
  /// Parameters:
  /// - screenKey: The unique key identifying the sensitive screen
  static bool hasDialogBeenShownInSession(String screenKey) {
    return _dialogsShownInSession.contains(screenKey);
  }
  
  /// Preloads dialog content in the background to improve performance
  /// 
  /// This method can be called during app initialization or when entering a section
  /// that might show security dialogs, to prepare the dialogs in advance
  /// 
  /// Parameters:
  /// - dialogKeys: List of dialog keys to preload status for
  static Future<void> preloadDialogStatus(List<String> dialogKeys) async {
    // Load all dialog statuses in parallel for better performance
    await Future.wait(
      dialogKeys.map((key) => SecureStorageService.read(key))
    );
  }
}