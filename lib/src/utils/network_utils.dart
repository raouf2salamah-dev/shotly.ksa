import 'package:flutter/material.dart';

/// Utility class for handling network operations with standardized error handling
class NetworkUtils {
  /// Executes a network operation with standardized error handling
  /// 
  /// Parameters:
  /// - context: The BuildContext for showing error messages
  /// - operation: The async operation to execute
  /// - setLoading: Function to update loading state
  /// - onSuccess: Callback for successful operation
  /// - errorMessage: Custom error message prefix (optional)
  /// - onError: Custom error handler (optional)
  /// - showRetry: Whether to show a retry button (optional)
  /// - retryOperation: Function to retry the operation (optional)
  static Future<void> executeWithErrorHandling<T>(
    BuildContext context, {
    required Future<T> Function() operation,
    required Function(bool) setLoading,
    required Function(T) onSuccess,
    String errorMessage = 'Error',
    Function(dynamic)? onError,
    bool showRetry = false,
    VoidCallback? retryOperation,
  }) async {
    setLoading(true);
    
    try {
      final result = await operation();
      onSuccess(result);
    } catch (e) {
      // Call custom error handler if provided
      if (onError != null) {
        onError(e);
      }
      
      // Show error message
      if (context.mounted) {
        _showErrorSnackBar(
          context, 
          '$errorMessage: ${e.toString()}',
          showRetry: showRetry,
          retryOperation: retryOperation,
        );
      }
    } finally {
      setLoading(false);
    }
  }
  
  /// Shows a standardized error SnackBar with optional retry button
  static void _showErrorSnackBar(
    BuildContext context, 
    String message, {
    bool showRetry = false,
    VoidCallback? retryOperation,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      action: showRetry && retryOperation != null ? SnackBarAction(
        label: 'Retry',
        onPressed: retryOperation,
      ) : null,
      duration: const Duration(seconds: 5),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}