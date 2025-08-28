// Simple script to log certificate validation failures
import 'dart:io';

void main() {
  final logDir = Directory('/Users/abdulraoufsalamah/Desktop/Pro/logs/security');
  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }
  
  final logFile = File('/Users/abdulraoufsalamah/Desktop/Pro/logs/security/certificate_failures.log');
  logFile.writeAsStringSync(
    "[${DateTime.now().toIso8601String()}] SSL Pinning validation failed – connection blocked\n", 
    mode: FileMode.append
  );
  
  print('Certificate validation failure logged');
}
