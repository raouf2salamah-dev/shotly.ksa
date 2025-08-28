import 'package:flutter/material.dart';
import 'logger.dart';

/// Example demonstrating how to use the Logger utility with conditional logging
class LoggerExample extends StatelessWidget {
  LoggerExample({Key? key}) : super(key: key);
  
  // Create a logger instance for this class
  final Logger _logger = Logger('LoggerExample');

  void _demonstrateLogging() {
    // Basic logging with different levels
    _logger.d('This is a debug message - only shown in debug builds');
    _logger.i('This is an info message');
    _logger.w('This is a warning message');
    _logger.e('This is an error message', error: Exception('Sample error'));
    _logger.c('This is a critical message', error: Exception('Critical error'), stackTrace: StackTrace.current);
    
    // Using the new conditional logging feature
    // This replaces the Swift-style conditional logging pattern:
    // #if DEBUG
    //   print("Debug: overlay added successfully")
    // #else
    //   // Production: log only minimal info
    //   os_log("Overlay protection initialized", type: .info)
    // #endif
    _logger.conditional(
      debugMessage: 'Debug: overlay added successfully',
      productionMessage: 'Overlay protection initialized',
      // Optional: customize log levels
      debugLevel: LogLevel.debug,
      productionLevel: LogLevel.info,
    );
    
    // Another example with different log levels
    _logger.conditional(
      debugMessage: 'Debug: User authentication details: email=test@example.com, method=oauth',
      productionMessage: 'User authenticated successfully',
      debugLevel: LogLevel.debug,
      productionLevel: LogLevel.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logger Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _demonstrateLogging,
              child: const Text('Test Logger'),
            ),
            const SizedBox(height: 20),
            const Text('Check console output to see logging results'),
          ],
        ),
      ),
    );
  }
}