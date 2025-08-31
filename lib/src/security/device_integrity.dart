import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';

/// DeviceIntegrity provides a simple way to check if a device has been
/// jailbroken (iOS) or rooted (Android), or if developer mode is enabled,
/// which may compromise security.
class DeviceIntegrity {
  /// Check if the device is compromised (jailbroken/rooted or developer mode enabled)
  /// 
  /// Returns true if the device is compromised
  static Future<bool> isCompromised() async {
    final jailbroken = await JailbreakRootDetection.instance.isJailBroken;
    final developerMode = await JailbreakRootDetection.instance.isDevMode;
    return jailbroken || developerMode;
  }
}