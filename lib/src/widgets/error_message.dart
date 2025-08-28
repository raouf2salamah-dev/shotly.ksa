import 'package:flutter/material.dart';

/// A standardized error message widget for consistent UI across the app
class ErrorMessage extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// Optional callback for retry button
  final VoidCallback? onRetry;
  
  /// Icon to display (defaults to error_outline)
  final IconData icon;
  
  /// Color of the icon (defaults to red)
  final Color iconColor;
  
  /// Size of the icon
  final double iconSize;
  
  /// Whether to show the error in a compact form (less padding)
  final bool compact;
  
  /// Creates an error message with optional retry button
  const ErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
    this.iconSize = 60,
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
            Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
            SizedBox(height: compact ? 8.0 : 16.0),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[  
              SizedBox(height: compact ? 8.0 : 16.0),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}