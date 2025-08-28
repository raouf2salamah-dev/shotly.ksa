import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter/foundation.dart';

/// DeviceIntegrity provides methods to check if a device has been
/// jailbroken (iOS) or rooted (Android), or if developer mode is enabled,
/// which may compromise security.
class DeviceIntegrity {
  /// Check if the device is compromised (jailbroken/rooted or developer mode enabled)
  /// 
  /// Returns true if the device is compromised
  static Future<bool> isCompromised() async {
    if (kIsWeb) return false; // Not applicable for web
    
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      final developerMode = await FlutterJailbreakDetection.developerMode;
      return jailbroken || developerMode;
    } catch (e) {
      // If detection fails, assume the device is not compromised
      debugPrint('Error detecting device integrity: $e');
      return false;
    }
  }
  
  /// Check if the device is jailbroken (iOS) or rooted (Android)
  /// 
  /// Returns true if the device is jailbroken/rooted
  static Future<bool> isJailbrokenOrRooted() async {
    if (kIsWeb) return false; // Not applicable for web
    
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      debugPrint('Error detecting jailbreak/root: $e');
      return false;
    }
  }
  
  /// Check if developer mode is enabled on the device
  /// 
  /// Returns true if developer mode is enabled
  static Future<bool> isDeveloperModeEnabled() async {
    if (kIsWeb) return false; // Not applicable for web
    
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (e) {
      debugPrint('Error detecting developer mode: $e');
      return false;
    }
  }
  
  /// Get a detailed report of device integrity checks
  /// 
  /// Returns a map with the results of each check
  static Future<Map<String, bool>> getIntegrityReport() async {
    if (kIsWeb) {
      return {
        'jailbroken_or_rooted': false,
        'developer_mode_enabled': false,
        'is_compromised': false,
        'is_web': true,
      };
    }
    
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      final developerMode = await FlutterJailbreakDetection.developerMode;
      
      return {
        'jailbroken_or_rooted': jailbroken,
        'developer_mode_enabled': developerMode,
        'is_compromised': jailbroken || developerMode,
        'is_web': false,
      };
    } catch (e) {
      debugPrint('Error generating integrity report: $e');
      return {
        'jailbroken_or_rooted': false,
        'developer_mode_enabled': false,
        'is_compromised': false,
        'is_web': false,
        'error_occurred': true,
      };
    }
  }
}