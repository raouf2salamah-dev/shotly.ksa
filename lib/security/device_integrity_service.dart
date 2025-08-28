import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceIntegrityResult {
  final bool isJailbrokenOrRooted;
  final bool developerMode;
  final bool isRealDevice;
  final bool canMockLocation;
  
  const DeviceIntegrityResult({
    required this.isJailbrokenOrRooted,
    required this.developerMode,
    this.isRealDevice = true,
    this.canMockLocation = false,
  });
  
  /// Returns true if any security risk is detected
  bool get compromised => 
      isJailbrokenOrRooted || 
      developerMode || 
      !isRealDevice || 
      canMockLocation;
}

/// Service to check device integrity and manage security warnings
class DeviceIntegrityService {
  static const _storage = FlutterSecureStorage();
  static const _warningShownKey = 'security_warning_shown';
  
  /// Check if the security warning has already been shown to the user
  static Future<bool> get warningAlreadyShown async {
    try {
      return await _storage.read(key: _warningShownKey) == 'true';
    } catch (e) {
      debugPrint('Error reading security warning status: $e');
      return false;
    }
  }
  
  /// Mark that the security warning has been shown to the user
  static Future<void> markWarningShown() async {
    try {
      await _storage.write(key: _warningShownKey, value: 'true');
    } catch (e) {
      debugPrint('Error saving security warning status: $e');
    }
  }
  
  /// Reset the warning shown status (for testing or after app updates)
  static Future<void> resetWarningShown() async {
    try {
      await _storage.delete(key: _warningShownKey);
    } catch (e) {
      debugPrint('Error resetting security warning status: $e');
    }
  }
  
  /// Check device integrity and return results
  static Future<DeviceIntegrityResult> check() async {
    if (kIsWeb) {
      // Web platform has different security concerns
      return const DeviceIntegrityResult(
        isJailbrokenOrRooted: false,
        developerMode: false,
        isRealDevice: true,
        canMockLocation: false,
      );
    }
    
    bool jailbroken = false;
    bool developerMode = false;
    bool isEmulator = false;
    bool canMockLocation = false;
    
    try {
      jailbroken = await FlutterJailbreakDetection.jailbroken;
      developerMode = await FlutterJailbreakDetection.developerMode;
      // The package doesn't have isRealDevice and canMockLocation methods
      // Using reasonable defaults instead
      isEmulator = false;
      canMockLocation = false;
    } catch (e) {
      debugPrint('Error checking device integrity: $e');
    }
    
    return DeviceIntegrityResult(
      isJailbrokenOrRooted: jailbroken,
      developerMode: developerMode,
      isRealDevice: !isEmulator,
      canMockLocation: canMockLocation,
    );
  }
}