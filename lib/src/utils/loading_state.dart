import 'package:flutter/material.dart';

/// Enum representing the different states of a loading operation
enum LoadingStatus {
  /// Initial state, no loading has occurred yet
  initial,
  
  /// Loading is in progress
  loading,
  
  /// Loading completed successfully
  success,
  
  /// Loading failed with an error
  error
}

/// A class to manage loading state with error handling
class LoadingState<T> {
  /// Current status of the loading operation
  final LoadingStatus status;
  
  /// Data loaded (if status is success)
  final T? data;
  
  /// Error message (if status is error)
  final String? errorMessage;
  
  /// Error object (if status is error)
  final dynamic error;
  
  /// Creates a loading state
  const LoadingState({
    required this.status,
    this.data,
    this.errorMessage,
    this.error,
  });
  
  /// Creates an initial loading state
  factory LoadingState.initial() => const LoadingState(status: LoadingStatus.initial);
  
  /// Creates a loading state
  factory LoadingState.loading() => const LoadingState(status: LoadingStatus.loading);
  
  /// Creates a success loading state with data
  factory LoadingState.success(T data) => LoadingState(
    status: LoadingStatus.success,
    data: data,
  );
  
  /// Creates an error loading state
  factory LoadingState.error(dynamic error, [String? message]) => LoadingState(
    status: LoadingStatus.error,
    errorMessage: message ?? error.toString(),
    error: error,
  );
  
  /// Whether the state is in loading status
  bool get isLoading => status == LoadingStatus.loading;
  
  /// Whether the state is in success status
  bool get isSuccess => status == LoadingStatus.success;
  
  /// Whether the state is in error status
  bool get isError => status == LoadingStatus.error;
  
  /// Whether the state is in initial status
  bool get isInitial => status == LoadingStatus.initial;
  
  /// Creates a copy of this LoadingState with the given fields replaced
  LoadingState<T> copyWith({
    LoadingStatus? status,
    T? data,
    String? errorMessage,
    dynamic error,
  }) {
    return LoadingState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      error: error ?? this.error,
    );
  }
}

/// Extension methods for BuildContext to handle loading states
extension LoadingStateExtension on BuildContext {
  /// Shows a standardized error SnackBar with optional retry button
  void showErrorSnackBar(
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
    
    ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }
}