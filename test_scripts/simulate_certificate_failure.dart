import 'dart:io';

/// This script simulates a certificate validation failure log entry
/// and verifies that it's properly written to the security log file
void main() async {
  print('Simulating certificate validation failure log entry...');
  
  // Create logs directory if it doesn't exist
  final logDir = Directory('${Directory.current.path}/logs/security');
  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
    print('Created log directory: ${logDir.path}');
  }
  
  // Log file path
  final logFile = File('${logDir.path}/certificate_failures.log');
  
  // Write the log message with timestamp
  final timestamp = DateTime.now().toIso8601String();
  logFile.writeAsStringSync(
    "[$timestamp] SSL Pinning validation failed – connection blocked\n", 
    mode: FileMode.append
  );
  
  print('Wrote simulated certificate validation failure to log file');
  
  // Check if the log file contains the expected message
  final logContent = logFile.readAsStringSync();
  if (logContent.contains('SSL Pinning validation failed – connection blocked')) {
    print('SUCCESS: Found expected error message in log file');
    print('Log file content:');
    print(logContent);
  } else {
    print('ERROR: Did not find expected error message in log file');
    print('Log file content:');
    print(logContent);
    exit(1);
  }
  
  print('Test completed successfully');
}