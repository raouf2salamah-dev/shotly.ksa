import 'package:flutter/material.dart';
import 'logger.dart';

/// Example demonstrating how to use the conditional logging feature
/// to replace Swift-style conditional compilation directives
class SecurityOverlay {
  final Logger _logger = Logger('SecurityOverlay');
  
  void addOverlay() {
    try {
      // Add security overlay implementation here
      
      // Use conditional logging to provide different information in debug vs production
      _logger.conditional(
        debugMessage: 'Debug: overlay added successfully with settings: blur=10, opacity=0.8',
        productionMessage: 'Overlay protection initialized',
        // Optional: customize log levels
        debugLevel: LogLevel.debug,
        productionLevel: LogLevel.info,
      );
    } catch (e) {
      _logger.e('Failed to add security overlay', error: e);
    }
  }
  
  void removeOverlay() {
    try {
      // Remove security overlay implementation here
      
      // Another example of conditional logging
      _logger.conditional(
        debugMessage: 'Debug: overlay removed with animation duration=300ms',
        productionMessage: 'Overlay removed',
      );
    } catch (e) {
      _logger.e('Failed to remove security overlay', error: e);
    }
  }
}

/// Example widget that uses the SecurityOverlay
class SecurityOverlayDemo extends StatelessWidget {
  final SecurityOverlay _securityOverlay = SecurityOverlay();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Overlay Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _securityOverlay.addOverlay,
              child: const Text('Add Security Overlay'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _securityOverlay.removeOverlay,
              child: const Text('Remove Security Overlay'),
            ),
          ],
        ),
      ),
    );
  }
}