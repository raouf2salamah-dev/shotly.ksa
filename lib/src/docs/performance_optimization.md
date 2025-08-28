# Performance Optimization Guide

This document provides an overview of the performance optimization features implemented in the application and how to use them effectively.

## Table of Contents

1. [Firestore Optimization](#firestore-optimization)
2. [Asset Optimization](#asset-optimization)
3. [Lazy Loading](#lazy-loading)
4. [Smart Image Loading](#smart-image-loading)
5. [Example Implementation](#example-implementation)

## Firestore Optimization

The `FirestoreOptimizer` class provides several features to optimize Firestore queries and data loading:

### Bundle Loading

Firestore bundles allow you to prepackage Firestore data and load it efficiently:

```dart
// Initialize in main.dart
await FirestoreOptimizer.enablePersistence();
await FirestoreOptimizer.loadBundle('common_data');

// Check if a bundle is loaded
bool isLoaded = await FirestoreOptimizer.isBundleLoaded('common_data');
```

### Optimized Queries

Create optimized Firestore queries with structured filters and ordering:

```dart
// Create an optimized query
final query = FirestoreOptimizer.createOptimizedQuery(
  collectionPath: 'products',
  filters: [
    QueryFilter(
      field: 'category',
      operator: FilterOperator.equals,
      value: 'electronics',
    ),
    QueryFilter(
      field: 'price',
      operator: FilterOperator.lessThan,
      value: 1000,
    ),
  ],
  orders: [
    QueryOrder(field: 'price', descending: false),
  ],
  limit: 20,
);

// Execute the query
final snapshot = await query.get();
```

### Collection Group Queries

Optimize collection group queries for better performance:

```dart
final query = FirestoreOptimizer.createOptimizedCollectionGroupQuery(
  collectionId: 'reviews',
  filters: [
    QueryFilter(
      field: 'rating',
      operator: FilterOperator.greaterThanOrEqual,
      value: 4,
    ),
  ],
);
```

## Asset Optimization

The `AssetOptimizer` class provides methods to optimize images and other assets:

### Image Compression

```dart
// Compress an asset image
final compressedBytes = await AssetOptimizer.compressAsset(
  assetPath: 'assets/images/large_image.jpg',
  quality: 85,
  maxWidth: 800,
  maxHeight: 600,
  format: CompressFormat.jpeg,
);

// Compress a file
final compressedFile = await AssetOptimizer.compressFile(
  file: File('/path/to/image.png'),
  quality: 80,
  maxWidth: 1200,
  format: CompressFormat.png,
);

// Compress raw data
final compressedData = await AssetOptimizer.compressData(
  data: imageBytes,
  quality: 90,
  format: CompressFormat.webp,
);
```

### Predefined Use Cases

Use predefined settings for common use cases:

```dart
// Get recommended settings for thumbnails
final thumbnailSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.thumbnail);

// Get recommended settings for list items
final listItemSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.listItem);

// Get recommended settings for fullscreen images
final fullscreenSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.fullscreen);
```

## Lazy Loading

The `LazyLoadingManager` class provides a way to lazily load resources:

### Basic Usage

```dart
// Get the singleton instance
final manager = LazyLoadingManager();

// Load a resource
final resource = await manager.loadResource(
  resourceId: 'unique_resource_id',
  loader: () async => await loadExpensiveResource(),
  priority: 1, // Higher priority resources load first
);

// Check if a resource is loaded
bool isLoaded = manager.isResourceLoaded('unique_resource_id');

// Clear the cache
manager.clearCache();

// Prioritize visible resources
manager.prioritizeVisibleResources();
```

### Using LazyLoadWidget

```dart
LazyLoadWidget(
  resourceId: 'image_123',
  loader: () => loadImageResource(),
  priority: 2,
  loadingBuilder: (context) => CircularProgressIndicator(),
  errorBuilder: (context, error) => Icon(Icons.error),
  builder: (context, resource) => Image.memory(resource),
);
```

## Deferred Loading

Deferred loading is a powerful technique to optimize app performance by loading libraries only when they are needed. This reduces initial load time and memory usage.

### Using DeferredLoader

The `DeferredLoader` utility simplifies working with deferred libraries:

```dart
// Import the library with deferred keyword
import 'package:image_picker/image_picker.dart' deferred as image_picker;
import '../utils/deferred_loader.dart';

// Create a loader
final _imagePickerLoader = DeferredLoader(image_picker.loadLibrary);

// Use it when needed
await _imagePickerLoader.ensureLoaded();
// Now you can use image_picker
final picker = image_picker.ImagePicker();
```

See the examples in `lib/src/examples/` for complete implementations with:
- Image picker
- File picker
- Video player
- Media validation

## Smart Image Loading

The `SmartImage` widget combines all optimization techniques for efficient image loading:

```dart
SmartImage(
  // Image source (use one of these)
  webImageUrl: 'https://example.com/image.jpg',
  assetImagePath: 'assets/images/local_image.png',
  localFilePath: '/path/to/file.jpg',
  webImageBytes: imageBytes,
  
  // Dimensions and styling
  width: 300,
  height: 200,
  fit: BoxFit.cover,
  
  // Optimization features
  lazyLoad: true,
  optimizeAssets: true,
  assetUseCase: AssetUseCase.listItem,
  
  // Caching options
  cacheWidth: 600,
  cacheHeight: 400,
  
  // Animation and transitions
  fadeInDuration: Duration(milliseconds: 300),
  
  // Hero animation
  useHeroTag: true,
  heroTag: 'image_hero_tag',
  
  // Custom builders
  loadingWidget: CustomLoadingWidget(),
  errorBuilder: (context, error) => CustomErrorWidget(),
);
```

## Example Implementation

See the `OptimizationExampleScreen` class in `lib/src/examples/optimization_example.dart` for a comprehensive example that demonstrates all optimization features working together.

Key features demonstrated in the example:

1. Firestore query optimization with filters and ordering
2. Pagination with optimized queries
3. Lazy loading of images with priority-based loading
4. Asset optimization with different use cases
5. Cache management
6. Performance monitoring

## Best Practices

1. **Initialize Early**: Enable Firestore persistence and load bundles during app initialization.
2. **Use Appropriate Asset Settings**: Choose the right compression settings based on the use case.
3. **Prioritize Visible Content**: Use `prioritizeVisibleResources()` when scrolling through lists.
4. **Monitor Performance**: Track loading times and resource usage to identify bottlenecks.
5. **Clear Cache When Needed**: Implement cache clearing for memory management.
6. **Combine Techniques**: Use all optimization techniques together for the best results.