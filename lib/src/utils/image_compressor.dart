import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressor {
  /// Compresses an image file and returns the compressed file
  /// 
  /// Parameters:
  /// - file: The image file to compress
  /// - quality: The quality of the compressed image (0-100)
  /// - maxWidth: The maximum width of the compressed image
  /// - maxHeight: The maximum height of the compressed image
  /// - format: The format of the compressed image (default: jpeg)
  static Future<File?> compressFile({
    required File file,
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1920,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      // Get file extension
      final extension = path.extension(file.path).toLowerCase();
      
      // Skip compression for already optimized formats like webp
      if (extension == '.webp' && format == CompressFormat.webp) {
        return file;
      }
      
      // Create target file path
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${path.basenameWithoutExtension(file.path)}_compressed${_getExtensionFromFormat(format)}',
      );
      
      // Compress the file
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: format,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }
  
  /// Compresses an image from memory (Uint8List) and returns the compressed data
  /// 
  /// Parameters:
  /// - data: The image data to compress
  /// - quality: The quality of the compressed image (0-100)
  /// - maxWidth: The maximum width of the compressed image
  /// - maxHeight: The maximum height of the compressed image
  /// - format: The format of the compressed image (default: jpeg)
  static Future<Uint8List?> compressData({
    required Uint8List data,
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1920,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      // Compress the data
      final result = await FlutterImageCompress.compressWithList(
        data,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: format,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error compressing image data: $e');
      return null;
    }
  }
  
  /// Determines if an image should be compressed based on its size
  static bool shouldCompress(File file, int maxSizeInBytes) {
    return file.lengthSync() > maxSizeInBytes;
  }
  
  /// Gets the appropriate file extension for the given compression format
  static String _getExtensionFromFormat(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return '.jpg';
      case CompressFormat.png:
        return '.png';
      case CompressFormat.webp:
        return '.webp';
      case CompressFormat.heic:
        return '.heic';
      default:
        return '.jpg';
    }
  }
  
  /// Suggests the best compression format based on the use case
  static CompressFormat suggestFormatForUseCase(ImageUseCase useCase) {
    switch (useCase) {
      case ImageUseCase.thumbnail:
        return CompressFormat.webp; // Best for thumbnails
      case ImageUseCase.profile:
        return CompressFormat.jpeg; // Good balance for photos
      case ImageUseCase.background:
        return CompressFormat.webp; // Efficient for large images
      case ImageUseCase.content:
        return CompressFormat.jpeg; // Good for content images
      case ImageUseCase.highQuality:
        return CompressFormat.png; // Lossless for high quality
      default:
        return CompressFormat.jpeg;
    }
  }
  
  /// Suggests compression quality based on the use case
  static int suggestQualityForUseCase(ImageUseCase useCase) {
    switch (useCase) {
      case ImageUseCase.thumbnail:
        return 70; // Lower quality for thumbnails
      case ImageUseCase.profile:
        return 85; // Good balance for profile photos
      case ImageUseCase.background:
        return 80; // Balanced for backgrounds
      case ImageUseCase.content:
        return 85; // Good for content images
      case ImageUseCase.highQuality:
        return 95; // High quality
      default:
        return 85;
    }
  }
}

/// Enum representing different image use cases
enum ImageUseCase {
  thumbnail,
  profile,
  background,
  content,
  highQuality,
}