import 'package:flutter/material.dart';
import 'loading_indicator.dart';

/// A widget that displays a loading overlay on top of its child
class LoadingOverlay extends StatelessWidget {
  /// The child widget to display
  final Widget child;
  
  /// Whether to show the loading overlay
  final bool isLoading;
  
  /// Optional text to display below the loading indicator
  final String? loadingText;
  
  /// Color of the overlay background
  final Color? overlayColor;
  
  /// Size of the loading indicator
  final double indicatorSize;
  
  /// Color of the loading indicator
  final Color? indicatorColor;

  /// Creates a loading overlay
  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
    this.overlayColor,
    this.indicatorSize = 48.0,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withOpacity(0.5),
            child: LoadingIndicator(
              message: loadingText,
              size: indicatorSize,
              color: indicatorColor ?? Colors.white,
            ),
          ),
      ],
    );
  }
}