import 'dart:io';

void main() {
  // Create logs directory if it doesn't exist
  final logDir = Directory('${Directory.current.path}/../logs/security');
  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }
  
  // Log file path
  final logFile = File('${logDir.path}/certificate_failures.log');
  
  // Write the log message with timestamp
  final timestamp = DateTime.now().toIso8601String();
  final logMessage = "[$timestamp] SSL Pinning validation failed – connection blocked";
  logFile.writeAsStringSync(logMessage + "\n", mode: FileMode.append);
  
  print('Certificate validation failure logged: $logMessage');
}
