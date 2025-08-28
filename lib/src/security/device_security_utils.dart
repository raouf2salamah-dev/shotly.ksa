import 'package:flutter/material.dart';
import 'device_integrity.dart';

/// Utility class for device security related functions
class DeviceSecurityUtils {
  /// Checks if the device is compromised and shows a warning dialog if it is.
  /// Optionally restricts features by calling the provided callback.
  /// 
  /// Returns true if the device is compromised, false otherwise.
  static Future<bool> checkDeviceIntegrityAndWarn({
    required BuildContext context,
    String title = 'Security Warning',
    String message = 'This device appears to be jailbroken/rooted or has developer mode enabled, '
        'which may compromise the security of your data. Some features may be '
        'restricted for your protection.',
    String buttonText = 'I Understand',
    Function()? onCompromisedDevice,
  }) async {
    // Check if device is compromised
    final isCompromised = await DeviceIntegrity.isCompromised();
    
    // If device is compromised, show warning and restrict features
    if (isCompromised && context.mounted) {
      // Show warning dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: Text(buttonText),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      
      // Call the callback to restrict features if provided
      if (onCompromisedDevice != null) {
        onCompromisedDevice();
      }
    }
    
    return isCompromised;
  }
}