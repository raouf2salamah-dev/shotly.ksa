import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../utils/asset_optimizer.dart';
import '../utils/lazy_loading_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// A service for preloading and optimizing essential app assets
/// 
/// This service ensures critical assets like logos, placeholders, and UI elements
/// are loaded and optimized during app initialization for first-time users
class AssetPreloadingService {
  static final AssetPreloadingService _instance = AssetPreloadingService._internal();
  
  /// Singleton instance
  factory AssetPreloadingService() => _instance;
  
  AssetPreloadingService._internal();
  
  final LazyLoadingManager _lazyLoadingManager = LazyLoadingManager();
  final Map<String, Uint8List> _preloadedAssets = {};
  
  /// List of essential assets that should be preloaded for first-time users
  final List<String> _essentialAssets = [
    'assets/images/placeholder.svg',
    'assets/images/placeholder2.svg',
    'assets/images/start.svg',
    'assets/images/ai.svg',
    'assets/images/easy.svg',
    'assets/images/security.svg',
    // Add other essential images here
  ];
  
  /// Preloads all essential assets for first-time users
  /// 
  /// This method should be called during app initialization
  Future<void> preloadEssentialAssets() async {
    debugPrint('🔄 Preloading essential assets...');
    
    final Map<String, Future<dynamic> Function()> resourceLoaders = {};
    
    // Create resource loaders for each essential asset
    for (final assetPath in _essentialAssets) {
      resourceLoaders[assetPath] = () => _loadAndOptimizeAsset(assetPath);
    }
    
    // Use LazyLoadingManager to prefetch all resources with high priority
    await _lazyLoadingManager.prefetchResources(
      resourceLoaders,
      priority: 10, // High priority
    );
    
    debugPrint('✅ Preloaded ${_preloadedAssets.length} essential assets');
  }
  
  /// Loads and optimizes an asset, storing it in memory for quick access
  Future<Uint8List?> _loadAndOptimizeAsset(String assetPath) async {
    try {
      // Check if asset is already preloaded
      if (_preloadedAssets.containsKey(assetPath)) {
        return _preloadedAssets[assetPath];
      }
      
      // Determine the appropriate use case based on the asset name
      AssetUseCase useCase = _determineUseCase(assetPath);
      
      // Get recommended settings for this use case
      final settings = AssetOptimizer.getRecommendedSettings(useCase);
      
      // Compress and optimize the asset
      final optimizedData = await AssetOptimizer.compressAsset(
        assetPath: assetPath,
        quality: settings['quality'] as int,
        maxWidth: settings['maxWidth'] as int?,
        maxHeight: settings['maxHeight'] as int?,
        format: settings['format'] as CompressFormat,
      );
      
      if (optimizedData != null) {
        // Store the optimized asset in memory
        _preloadedAssets[assetPath] = optimizedData;
        debugPrint('📦 Preloaded and optimized: $assetPath');
        return optimizedData;
      }
      
      // If optimization fails, load the asset directly
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      _preloadedAssets[assetPath] = bytes;
      debugPrint('📦 Preloaded (unoptimized): $assetPath');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error preloading asset $assetPath: $e');
      return null;
    }
  }
  
  /// Determines the appropriate use case for an asset based on its name
  AssetUseCase _determineUseCase(String assetPath) {
    final String fileName = assetPath.split('/').last.toLowerCase();
    
    if (fileName.contains('logo') || fileName.contains('icon')) {
      return AssetUseCase.icon;
    } else if (fileName.contains('placeholder') || fileName.contains('thumbnail')) {
      return AssetUseCase.thumbnail;
    } else if (fileName.contains('avatar') || fileName.contains('profile')) {
      return AssetUseCase.listItem;
    } else {
      return AssetUseCase.fullscreen;
    }
  }
  
  /// Gets a preloaded asset by path
  /// 
  /// Returns null if the asset hasn't been preloaded
  Uint8List? getPreloadedAsset(String assetPath) {
    return _preloadedAssets[assetPath];
  }
  
  /// Checks if an asset has been preloaded
  bool isAssetPreloaded(String assetPath) {
    return _preloadedAssets.containsKey(assetPath);
  }
  
  /// Clears all preloaded assets from memory
  void clearPreloadedAssets() {
    _preloadedAssets.clear();
    debugPrint('🧹 Cleared all preloaded assets');
  }
}