import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/asset_optimizer.dart';
import '../utils/lazy_loading_manager.dart';
import '../services/asset_preloading_service.dart';

class SmartImage extends StatelessWidget {
  final String webImageUrl;
  final String assetImagePath;
  final String localFilePath;
  final Uint8List? webImageBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget? loadingWidget;
  final bool lazyLoad;
  final int? cacheWidth;
  final int? cacheHeight;
  final Duration fadeInDuration;
  final bool useHeroTag;
  final String? heroTag;
  final bool optimizeAssets;
  final AssetUseCase assetUseCase;

  const SmartImage({
    Key? key,
    this.webImageUrl = '',
    required this.assetImagePath,
    this.localFilePath = '',
    this.webImageBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.loadingWidget,
    this.lazyLoad = true,
    this.cacheWidth,
    this.cacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.useHeroTag = false,
    this.heroTag,
    this.optimizeAssets = true,
    this.assetUseCase = AssetUseCase.listItem,
  }) : super(key: key);

  // Helper method to load image resource for lazy loading
  Future<dynamic> _loadImageResource(BuildContext context, bool isSvg) async {
    try {
      // For web platform
      if (kIsWeb) {
        if (webImageBytes != null) {
          return webImageBytes;
        } else if (webImageUrl.isNotEmpty) {
          return webImageUrl;
        } else {
          return assetImagePath;
        }
      }
      
      // For non-web platforms
      if (localFilePath.isNotEmpty) {
        final file = io.File(localFilePath);
        if (await file.exists()) {
          if (optimizeAssets) {
            // Optimize the image file
            final settings = AssetOptimizer.getRecommendedSettings(assetUseCase);
            return AssetOptimizer.compressFile(
              file: file,
              quality: settings['quality'] as int,
              maxWidth: settings['maxWidth'] as int?,
              maxHeight: settings['maxHeight'] as int?,
              format: settings['format'] as CompressFormat,
            );
          } else {
            return file;
          }
        }
      }
      
      if (assetImagePath.isNotEmpty) {
        // Check if the asset is already preloaded
        final preloadedAsset = AssetPreloadingService().getPreloadedAsset(assetImagePath);
        if (preloadedAsset != null) {
          debugPrint('Using preloaded asset: $assetImagePath');
          return preloadedAsset;
        }
        
        if (isSvg) {
          return assetImagePath; // SVG doesn't need optimization
        } else if (optimizeAssets) {
          // Optimize the asset image
          final settings = AssetOptimizer.getRecommendedSettings(assetUseCase);
          return AssetOptimizer.compressAsset(
            assetPath: assetImagePath,
            quality: settings['quality'] as int,
            maxWidth: settings['maxWidth'] as int?,
            maxHeight: settings['maxHeight'] as int?,
            format: settings['format'] as CompressFormat,
          );
        } else {
          return assetImagePath;
        }
      }
      
      if (webImageUrl.isNotEmpty) {
        return webImageUrl;
      }
      
      throw Exception('No valid image source provided');
    } catch (e) {
      debugPrint('Error loading image resource: $e');
      rethrow;
    }
  }
  
  // Helper method to build the image widget based on the loaded resource
  Widget _buildImageWidget(BuildContext context, dynamic imageData, bool isSvg, 
      Widget Function(BuildContext, String) defaultErrorBuilder) {
    Widget imageWidget;
    
    if (imageData is Uint8List) {
      // Build from memory data
      imageWidget = Image.memory(
        imageData,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) => 
          errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
      );
    } else if (imageData is io.File) {
      // Build from file
      imageWidget = Image.file(
        imageData,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) => 
          errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
      );
    } else if (imageData is String) {
      if (isSvg) {
        // Build SVG
        imageWidget = SvgPicture.asset(
          imageData,
          width: width,
          height: height,
          fit: fit,
        );
      } else if (imageData.startsWith('http')) {
        // Build from network URL
        imageWidget = CachedNetworkImage(
          imageUrl: imageData,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: fadeInDuration,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          maxWidthDiskCache: 800,
          maxHeightDiskCache: 800,
          placeholder: (context, url) => loadingWidget ?? Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => 
            errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
        );
      } else {
        // Build from asset path
        imageWidget = Image.asset(
          imageData,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) => 
            errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
        );
      }
    } else {
      // Fallback to placeholder
      imageWidget = Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
    
    // Apply Hero animation if needed
    if (useHeroTag && heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  @override
  Widget build(BuildContext context) {
    // Default error widget
    final defaultErrorBuilder = (BuildContext context, String error) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      );
    };
    
    // Default loading widget
    final defaultLoadingWidget = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Check if the asset is an SVG
    final bool isSvg = assetImagePath.toLowerCase().endsWith('.svg');
    
    // Generate a unique resource ID for lazy loading
    final String resourceId = useHeroTag && heroTag != null 
        ? heroTag! 
        : '${webImageUrl}_${assetImagePath}_${localFilePath}';
    
    // Use LazyLoadWidget if lazyLoad is enabled
    if (lazyLoad) {
      return LazyLoadWidget(
        resourceId: resourceId,
        priority: 0,
        loader: () => _loadImageResource(context, isSvg),
        loadingBuilder: (context) => loadingWidget ?? defaultLoadingWidget,
        errorBuilder: (context, error) => 
          errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
        builder: (context, imageData) {
          return _buildImageWidget(context, imageData, isSvg, defaultErrorBuilder);
        },
      );
    }
    
    // Create the image widget based on the source
    Widget imageWidget;
    
    if (kIsWeb) {
      // For web platform
      // First try to use webImageBytes if available
      if (webImageBytes != null) {
        imageWidget = Image.memory(
          webImageBytes!,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) => 
            errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
        );
      }
      // Then try to use the web image URL
      else if (webImageUrl.isNotEmpty) {
        imageWidget = CachedNetworkImage(
          imageUrl: webImageUrl,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: fadeInDuration,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          placeholder: (context, url) => loadingWidget ?? defaultLoadingWidget,
          errorWidget: (context, url, error) {
            // Fallback to asset image if network image fails
            if (isSvg) {
              return SvgPicture.asset(
                assetImagePath,
                width: width,
                height: height,
                fit: fit,
              );
            } else {
              return Image.asset(
                assetImagePath,
                width: width,
                height: height,
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                errorBuilder: (context, error, stackTrace) => 
                  errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
              );
            }
          },
          // Optimize memory usage
          maxWidthDiskCache: 800,
          maxHeightDiskCache: 800,
          // Improve loading performance
          progressIndicatorBuilder: lazyLoad ? (context, url, downloadProgress) => 
            Center(child: CircularProgressIndicator(value: downloadProgress.progress)) : null,
        );
      } else {
        // If no web URL or bytes are provided, use asset directly
        if (isSvg) {
          imageWidget = SvgPicture.asset(
            assetImagePath,
            width: width,
            height: height,
            fit: fit,
          );
        } else {
          imageWidget = Image.asset(
            assetImagePath,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (context, error, stackTrace) => 
              errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
          );
        }
      }
    } else {
      // For non-web platforms
      if (localFilePath.isNotEmpty) {
        try {
          // Display image from local file on mobile/desktop
          final file = io.File(localFilePath);
          if (file.existsSync()) {
            imageWidget = Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              errorBuilder: (context, error, stackTrace) => 
                errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
            );
          } else {
            throw Exception('File does not exist');
          }
        } catch (e) {
          // Fall back to asset image if local file fails to load
          if (webImageUrl.isNotEmpty) {
            imageWidget = CachedNetworkImage(
              imageUrl: webImageUrl,
              width: width,
              height: height,
              fit: fit,
              fadeInDuration: fadeInDuration,
              memCacheWidth: cacheWidth,
              memCacheHeight: cacheHeight,
              placeholder: (context, url) => loadingWidget ?? defaultLoadingWidget,
              errorWidget: (context, url, error) {
                // Fallback to asset image if network image fails
                if (isSvg) {
                  return SvgPicture.asset(
                    assetImagePath,
                    width: width,
                    height: height,
                    fit: fit,
                  );
                } else {
                  return Image.asset(
                    assetImagePath,
                    width: width,
                    height: height,
                    fit: fit,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                    errorBuilder: (context, error, stackTrace) => 
                      errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
                  );
                }
              },
              maxWidthDiskCache: 800,
              maxHeightDiskCache: 800,
              progressIndicatorBuilder: lazyLoad ? (context, url, downloadProgress) => 
                Center(child: CircularProgressIndicator(value: downloadProgress.progress)) : null,
            );
          } else {
            // Use asset image as fallback
            if (isSvg) {
              imageWidget = SvgPicture.asset(
                assetImagePath,
                width: width,
                height: height,
                fit: fit,
              );
            } else {
              imageWidget = Image.asset(
                assetImagePath,
                width: width,
                height: height,
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                errorBuilder: (context, error, stackTrace) => 
                  errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
              );
            }
          }
        }
      } else if (webImageUrl.isNotEmpty) {
        // Try to use web image URL if no local file
        imageWidget = CachedNetworkImage(
          imageUrl: webImageUrl,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: fadeInDuration,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          placeholder: (context, url) => loadingWidget ?? defaultLoadingWidget,
          errorWidget: (context, url, error) {
            // Fallback to asset image if network image fails
            if (isSvg) {
              return SvgPicture.asset(
                assetImagePath,
                width: width,
                height: height,
                fit: fit,
              );
            } else {
              return Image.asset(
                assetImagePath,
                width: width,
                height: height,
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                errorBuilder: (context, error, stackTrace) => 
                  errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
              );
            }
          },
          maxWidthDiskCache: 800,
          maxHeightDiskCache: 800,
          progressIndicatorBuilder: lazyLoad ? (context, url, downloadProgress) => 
            Center(child: CircularProgressIndicator(value: downloadProgress.progress)) : null,
        );
      } else {
        // Use asset image as fallback
        if (isSvg) {
          imageWidget = SvgPicture.asset(
            assetImagePath,
            width: width,
            height: height,
            fit: fit,
          );
        } else {
          imageWidget = Image.asset(
            assetImagePath,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (context, error, stackTrace) => 
              errorBuilder != null ? errorBuilder!(context, error.toString()) : defaultErrorBuilder(context, error.toString()),
          );
        }
      }
    }
    
    // Apply Hero animation if requested
    if (useHeroTag && heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
}