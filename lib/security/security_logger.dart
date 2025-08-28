import 'dart:developer';

/// A utility class for logging security-related events
/// with consistent formatting and timestamps
class SecurityLogger {
  static void log(String event, {String? detail}) {
    final timestamp = DateTime.now().toIso8601String();
    log('[SECURITY][$timestamp] $event ${detail ?? ''}');
  }
}