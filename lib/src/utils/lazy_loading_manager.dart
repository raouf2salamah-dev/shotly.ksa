import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

/// A utility class to manage lazy loading of resources throughout the app
class LazyLoadingManager {
  static final LazyLoadingManager _instance = LazyLoadingManager._internal();
  
  /// Singleton instance
  factory LazyLoadingManager() => _instance;
  
  LazyLoadingManager._internal();
  
  /// Map to track loading status of resources by their unique identifiers
  final Map<String, bool> _loadingStatus = {};
  
  /// Map to cache loaded resources by their unique identifiers
  final Map<String, dynamic> _resourceCache = {};
  
  /// Stream controllers for resource loading events
  final Map<String, StreamController<dynamic>> _loadingControllers = {};
  
  /// Maximum number of concurrent loading operations
  int _maxConcurrentLoads = 5;
  
  /// Queue of pending load operations
  final List<_LoadOperation> _loadQueue = [];
  
  /// Number of currently active loading operations
  int _activeLoads = 0;
  
  /// Sets the maximum number of concurrent loading operations
  set maxConcurrentLoads(int value) {
    _maxConcurrentLoads = value;
    _processQueue();
  }
  
  /// Gets the maximum number of concurrent loading operations
  int get maxConcurrentLoads => _maxConcurrentLoads;
  
  /// Checks if a resource is currently loading
  bool isLoading(String resourceId) {
    return _loadingStatus[resourceId] ?? false;
  }

  /// Checks if a resource has been loaded and is cached
  bool isResourceLoaded(String resourceId) {
    return _resourceCache.containsKey(resourceId);
  }
  
  /// Gets a cached resource if available
  dynamic getCachedResource(String resourceId) {
    return _resourceCache[resourceId];
  }
  
  /// Clears a specific resource from the cache
  void clearResourceCache(String resourceId) {
    _resourceCache.remove(resourceId);
  }
  
  /// Clears all resources from the cache
  void clearAllCache() {
    _resourceCache.clear();
  }

  /// Returns the number of cached resources
  int getCachedResourcesCount() {
    return _resourceCache.length;
  }
  
  /// Loads a resource with the given loader function
  /// 
  /// Parameters:
  /// - resourceId: A unique identifier for the resource
  /// - loader: A function that loads the resource
  /// - priority: The priority of the load operation (higher = more important)
  /// - forceReload: Whether to force reload even if the resource is cached
  Future<T> loadResource<T>(
    String resourceId,
    Future<T> Function() loader, {
    int priority = 0,
    bool forceReload = false,
  }) async {
    // Check if resource is already cached and not forcing reload
    if (!forceReload && _resourceCache.containsKey(resourceId)) {
      return _resourceCache[resourceId] as T;
    }
    
    // Check if resource is already loading
    if (_loadingStatus[resourceId] == true) {
      // Wait for the resource to finish loading
      final completer = Completer<T>();
      
      if (!_loadingControllers.containsKey(resourceId)) {
        _loadingControllers[resourceId] = StreamController<dynamic>.broadcast();
      }
      
      _loadingControllers[resourceId]!.stream.listen(
        (data) {
          if (!completer.isCompleted) {
            completer.complete(data as T);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );
      
      return completer.future;
    }
    
    // Mark resource as loading
    _loadingStatus[resourceId] = true;
    
    // Create a load operation
    final completer = Completer<T>();
    final operation = _LoadOperation<T>(
      resourceId: resourceId,
      loader: loader,
      completer: completer,
      priority: priority,
    );
    
    // Add to queue and process
    _loadQueue.add(operation);
    _sortQueue();
    _processQueue();
    
    return completer.future;
  }
  
  /// Sorts the load queue by priority (descending)
  void _sortQueue() {
    _loadQueue.sort((a, b) => b.priority.compareTo(a.priority));
  }
  
  /// Processes the load queue
  void _processQueue() {
    while (_activeLoads < _maxConcurrentLoads && _loadQueue.isNotEmpty) {
      final operation = _loadQueue.removeAt(0);
      _activeLoads++;
      
      _executeLoad(operation);
    }
  }
  
  /// Executes a load operation
  Future<void> _executeLoad(_LoadOperation operation) async {
    try {
      final result = await operation.loader();
      
      // Cache the result
      _resourceCache[operation.resourceId] = result;
      
      // Complete the operation
      if (!operation.completer.isCompleted) {
        operation.completer.complete(result);
      }
      
      // Notify any listeners
      if (_loadingControllers.containsKey(operation.resourceId)) {
        _loadingControllers[operation.resourceId]!.add(result);
      }
    } catch (error) {
      // Handle error
      if (!operation.completer.isCompleted) {
        operation.completer.completeError(error);
      }
      
      // Notify any listeners
      if (_loadingControllers.containsKey(operation.resourceId)) {
        _loadingControllers[operation.resourceId]!.addError(error);
      }
      
      debugPrint('Error loading resource ${operation.resourceId}: $error');
    } finally {
      // Mark resource as not loading
      _loadingStatus[operation.resourceId] = false;
      
      // Clean up controller if no more listeners
      if (_loadingControllers.containsKey(operation.resourceId) &&
          !_loadingControllers[operation.resourceId]!.hasListener) {
        _loadingControllers[operation.resourceId]!.close();
        _loadingControllers.remove(operation.resourceId);
      }
      
      // Decrement active loads and process queue
      _activeLoads--;
      _processQueue();
    }
  }
  
  /// Prioritizes loading of visible resources
  void prioritizeVisibleResources(List<String> visibleResourceIds, {int priority = 10}) {
    // Increase priority of visible resources in the queue
    for (final operation in _loadQueue) {
      if (visibleResourceIds.contains(operation.resourceId)) {
        operation.priority = priority;
      }
    }
    
    // Re-sort the queue
    _sortQueue();
  }
  
  /// Cancels loading of a resource
  void cancelLoading(String resourceId) {
    // Remove from queue
    _loadQueue.removeWhere((op) => op.resourceId == resourceId);
    
    // Mark as not loading
    _loadingStatus[resourceId] = false;
  }
  
  /// Prefetches a list of resources
  Future<void> prefetchResources(
    Map<String, Future<dynamic> Function()> resources, {
    int priority = -1,
  }) async {
    final futures = <Future>[];
    
    for (final entry in resources.entries) {
      futures.add(
        loadResource(
          entry.key,
          entry.value,
          priority: priority,
        ),
      );
    }
    
    await Future.wait(futures);
  }
  
  /// Resets the manager for testing purposes
  @visibleForTesting
  void resetForTesting() {
    _resourceCache.clear();
    _loadingStatus.clear();
    _loadQueue.clear();
    _activeLoads = 0;
    _loadingControllers.values.forEach((controller) => controller.close());
    _loadingControllers.clear();
    _maxConcurrentLoads = 5;
  }
}

/// Represents a load operation in the queue
class _LoadOperation<T> {
  final String resourceId;
  final Future<T> Function() loader;
  final Completer<T> completer;
  int priority;
  
  _LoadOperation({
    required this.resourceId,
    required this.loader,
    required this.completer,
    this.priority = 0,
  });
}

/// A widget that lazily loads resources when they become visible
class LazyLoadWidget extends StatefulWidget {
  final String resourceId;
  final Future<dynamic> Function() loader;
  final Widget Function(BuildContext context, dynamic resource) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final int priority;
  final bool forceReload;
  
  const LazyLoadWidget({
    Key? key,
    required this.resourceId,
    required this.loader,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.priority = 0,
    this.forceReload = false,
  }) : super(key: key);
  
  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  late Future<dynamic> _resourceFuture;
  final LazyLoadingManager _manager = LazyLoadingManager();
  
  @override
  void initState() {
    super.initState();
    _loadResource();
  }
  
  @override
  void didUpdateWidget(LazyLoadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceId != widget.resourceId || widget.forceReload) {
      _loadResource();
    }
  }
  
  void _loadResource() {
    _resourceFuture = _manager.loadResource(
      widget.resourceId,
      widget.loader,
      priority: widget.priority,
      forceReload: widget.forceReload,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _resourceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ?? 
              const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ?? 
              Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return widget.builder(context, snapshot.data);
        }
      },
    );
  }
}