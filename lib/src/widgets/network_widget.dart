import 'package:flutter/material.dart';
import '../utils/loading_state.dart';
import 'error_message.dart';
import 'loading_indicator.dart';

/// A widget that handles different states of network operations
/// 
/// This widget provides a standardized way to handle loading, error, and success states
/// for network operations across the app.
class NetworkWidget<T> extends StatelessWidget {
  /// The current loading state
  final LoadingState<T> loadingState;
  
  /// Builder function for the content when loading is successful
  final Widget Function(BuildContext, T) builder;
  
  /// Optional custom loading widget
  final Widget? loadingWidget;
  
  /// Optional loading message
  final String? loadingMessage;
  
  /// Optional custom error widget
  final Widget? errorWidget;
  
  /// Optional retry callback for error state
  final VoidCallback? onRetry;
  
  /// Optional initial widget to show when in initial state
  final Widget? initialWidget;
  
  /// Whether to show the loading indicator in a compact form
  final bool compactLoading;
  
  /// Creates a network widget
  const NetworkWidget({
    super.key,
    required this.loadingState,
    required this.builder,
    this.loadingWidget,
    this.loadingMessage,
    this.errorWidget,
    this.onRetry,
    this.initialWidget,
    this.compactLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (loadingState.status) {
      case LoadingStatus.initial:
        return initialWidget ?? const SizedBox.shrink();
        
      case LoadingStatus.loading:
        return loadingWidget ?? LoadingIndicator(
          message: loadingMessage,
          compact: compactLoading,
        );
        
      case LoadingStatus.success:
        // We know data is not null when status is success
        return builder(context, loadingState.data as T);
        
      case LoadingStatus.error:
        return errorWidget ?? ErrorMessage(
          message: loadingState.errorMessage ?? 'An error occurred',
          onRetry: onRetry,
          compact: compactLoading,
        );
    }
  }
}

/// A stateful widget that handles network operations with loading state
class NetworkStateWidget<T> extends StatefulWidget {
  /// The future that loads the data
  final Future<T> Function() future;
  
  /// Builder function for the content when loading is successful
  final Widget Function(BuildContext, T) builder;
  
  /// Optional loading message
  final String? loadingMessage;
  
  /// Optional error message prefix
  final String? errorMessagePrefix;
  
  /// Optional retry callback for error state
  final VoidCallback? onRetry;
  
  /// Whether to automatically load data on init
  final bool autoLoad;
  
  /// Whether to show the loading indicator in a compact form
  final bool compactLoading;
  
  /// Creates a network state widget
  const NetworkStateWidget({
    super.key,
    required this.future,
    required this.builder,
    this.loadingMessage,
    this.errorMessagePrefix,
    this.onRetry,
    this.autoLoad = true,
    this.compactLoading = false,
  });

  @override
  State<NetworkStateWidget<T>> createState() => _NetworkStateWidgetState<T>();
}

class _NetworkStateWidgetState<T> extends State<NetworkStateWidget<T>> {
  late LoadingState<T> _loadingState;
  
  @override
  void initState() {
    super.initState();
    _loadingState = LoadingState.initial();
    
    if (widget.autoLoad) {
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    if (_loadingState.isLoading) return;
    
    setState(() {
      _loadingState = LoadingState.loading();
    });
    
    try {
      final data = await widget.future();
      if (mounted) {
        setState(() {
          _loadingState = LoadingState.success(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final prefix = widget.errorMessagePrefix ?? 'Error';
          _loadingState = LoadingState.error(e, '$prefix: ${e.toString()}');
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return NetworkWidget<T>(
      loadingState: _loadingState,
      builder: widget.builder,
      loadingMessage: widget.loadingMessage,
      onRetry: widget.onRetry ?? _loadData,
      compactLoading: widget.compactLoading,
    );
  }
}