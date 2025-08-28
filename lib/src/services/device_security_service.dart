import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter/material.dart';

/// DeviceSecurityService provides methods to check if a device has been
/// jailbroken (iOS) or rooted (Android), which may compromise security
class DeviceSecurityService {
  static final DeviceSecurityService _instance = DeviceSecurityService._internal();
  
  // Cache the result to avoid repeated checks
  bool? _isJailbrokenOrRooted;
  
  // Singleton pattern
  factory DeviceSecurityService() {
    return _instance;
  }
  
  DeviceSecurityService._internal();
  
  /// Check if the device is jailbroken (iOS) or rooted (Android)
  /// 
  /// Returns true if the device is compromised
  Future<bool> isDeviceCompromised() async {
    // Return cached result if available
    if (_isJailbrokenOrRooted != null) {
      return _isJailbrokenOrRooted!;
    }
    
    try {
      // Check for jailbreak/root
      _isJailbrokenOrRooted = await FlutterJailbreakDetection.jailbroken;
      return _isJailbrokenOrRooted!;
    } catch (e) {
      print('Error checking device security status: $e');
      // Default to false if check fails
      return false;
    }
  }
  
  /// Check if developer mode is enabled (Android only)
  /// 
  /// Returns true if developer mode is enabled
  Future<bool> isDeveloperModeEnabled() async {
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (e) {
      print('Error checking developer mode: $e');
      // Default to false if check fails
      return false;
    }
  }
  
  /// Show a security warning dialog if the device is compromised
  /// 
  /// [context] - The BuildContext for showing the dialog
  /// Returns true if the device is compromised and the dialog was shown
  Future<bool> checkAndShowWarningIfNeeded(BuildContext context) async {
    final isCompromised = await isDeviceCompromised();
    
    if (isCompromised) {
      // Show warning dialog
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Security Warning'),
              content: const Text(
                'This device appears to be jailbroken or rooted, which may compromise ' +
                'the security of your data. Using this app on a compromised device ' +
                'is not recommended.\n\nProceed at your own risk.'
              ),
              actions: [
                TextButton(
                  child: const Text('I Understand'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return true;
    }
    
    return false;
  }
  
  /// Reset the cached security status
  /// This can be useful if you want to force a fresh check
  void resetSecurityStatus() {
    _isJailbrokenOrRooted = null;
  }
}