import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'crashlytics_helper.dart';

/// A utility class to test Firebase functionality
class FirebaseTest {
  /// Test Firebase Crashlytics by forcing a crash
  static void testCrashlytics(BuildContext context) {
    try {
      // Log a message to Crashlytics
      CrashlyticsHelper.log('Testing Crashlytics');
      
      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Crashlytics'),
          content: const Text(
            'This will send a test exception to Firebase Crashlytics. '
            'The app will not crash, but you will see the error in the Firebase console.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendTestException();
              },
              child: const Text('Send Test Exception'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error testing Crashlytics: $e');
    }
  }
  
  /// Send a test exception to Crashlytics
  static Future<void> _sendTestException() async {
    try {
      // Record a non-fatal error
      await CrashlyticsHelper.recordError(
        Exception('This is a test exception'),
        StackTrace.current,
        reason: 'Testing Crashlytics',
      );
      
      debugPrint('Test exception sent to Crashlytics');
    } catch (e) {
      debugPrint('Error sending test exception: $e');
    }
  }
  
  /// Force a crash for testing (use with caution)
  static void forceCrash() {
    CrashlyticsHelper.instance.crash();
  }
}