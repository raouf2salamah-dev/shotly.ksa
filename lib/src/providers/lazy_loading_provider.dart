import 'package:flutter/material.dart';
import '../utils/lazy_loading_manager.dart';

/// Provider for the LazyLoadingManager
class LazyLoadingProvider extends InheritedWidget {
  final LazyLoadingManager manager;
  
  const LazyLoadingProvider({
    Key? key,
    required this.manager,
    required Widget child,
  }) : super(key: key, child: child);
  
  /// Get the LazyLoadingManager instance from the context
  static LazyLoadingManager of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<LazyLoadingProvider>();
    if (provider == null) {
      throw Exception('LazyLoadingProvider not found in the widget tree');
    }
    return provider.manager;
  }
  
  @override
  bool updateShouldNotify(LazyLoadingProvider oldWidget) {
    return manager != oldWidget.manager;
  }
}