import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// DeviceIntegrity provides a simple way to check if a device has been
/// jailbroken (iOS) or rooted (Android), or if developer mode is enabled,
/// which may compromise security.
class DeviceIntegrity {
  /// Check if the device is compromised (jailbroken/rooted or developer mode enabled)
  /// 
  /// Returns true if the device is compromised
  static Future<bool> isCompromised() async {
    final jailbroken = await FlutterJailbreakDetection.jailbroken;
    final developerMode = await FlutterJailbreakDetection.developerMode;
    return jailbroken || developerMode;
  }
}