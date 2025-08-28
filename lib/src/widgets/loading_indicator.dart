import 'package:flutter/material.dart';

/// A standardized loading indicator widget for consistent UI across the app
class LoadingIndicator extends StatelessWidget {
  /// Optional message to display below the loading indicator
  final String? message;
  
  /// Size of the loading indicator
  final double size;
  
  /// Color of the loading indicator (uses theme's primary color if not specified)
  final Color? color;
  
  /// Whether to show the indicator in a compact form (less padding)
  final bool compact;
  
  /// Creates a loading indicator with optional message
  const LoadingIndicator({
    super.key, 
    this.message,
    this.size = 36.0,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            if (message != null) ...[  
              SizedBox(height: compact ? 8.0 : 16.0),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}