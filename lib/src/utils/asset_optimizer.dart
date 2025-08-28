import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// A utility class for optimizing assets in the app
class AssetOptimizer {
  static dynamic compressor = FlutterImageCompress;
  /// Compresses an asset image and returns the compressed data
  /// 
  /// Parameters:
  /// - assetPath: The path to the asset in the assets folder
  /// - quality: The quality of the compressed image (0-100)
  /// - maxWidth: The maximum width of the compressed image
  /// - maxHeight: The maximum height of the compressed image
  /// - format: The format to compress to
  static Future<Uint8List?> compressAsset({
    required String assetPath,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      // Load the asset
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Compress the image
      final result = await compressImage(
        bytes: bytes,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        format: format,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error compressing asset: $e');
      return null;
    }
  }
  
  /// Compresses an image from a file and returns the compressed data
  /// 
  /// Parameters:
  /// - file: The file to compress
  /// - quality: The quality of the compressed image (0-100)
  /// - maxWidth: The maximum width of the compressed image
  /// - maxHeight: The maximum height of the compressed image
  /// - format: The format to compress to
  static Future<Uint8List?> compressFile({
    required File file,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      // Get a temporary file path
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${path.basenameWithoutExtension(file.path)}_compressed.${_getExtensionFromFormat(format)}',
      );
      
      // Compress the file
      final result = await compressor.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? 1,
        minHeight: maxHeight ?? 1,
        format: format,
      );
      
      if (result != null) {
        final compressedData = await result.readAsBytes();
        // No need to delete as it's not a file
        return compressedData;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error compressing file: $e');
      return null;
    }
  }
  
  /// Compresses an image from memory and returns the compressed data
  /// 
  /// Parameters:
  /// - bytes: The image data to compress
  /// - quality: The quality of the compressed image (0-100)
  /// - maxWidth: The maximum width of the compressed image
  /// - maxHeight: The maximum height of the compressed image
  /// - format: The format to compress to
  static Future<Uint8List?> compressImage({
    required Uint8List bytes,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      // Compress the image
      final result = await compressor.compressWithList(
        bytes,
        quality: quality,
        minWidth: maxWidth ?? 1,
        minHeight: maxHeight ?? 1,
        format: format,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error compressing image data: $e');
      return null;
    }
  }
  
  /// Determines if an image should be compressed based on its size
  /// 
  /// Parameters:
  /// - bytes: The image data
  /// - threshold: The size threshold in bytes
  static bool shouldCompress(Uint8List bytes, {int threshold = 100 * 1024}) {
    return bytes.length > threshold;
  }
  
  /// Gets the file extension from a compress format
  static String _getExtensionFromFormat(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return 'jpg';
      case CompressFormat.png:
        return 'png';
      case CompressFormat.webp:
        return 'webp';
      case CompressFormat.heic:
        return 'heic';
      default:
        return 'jpg';
    }
  }
  
  /// Gets the recommended compression settings for a specific use case
  static Map<String, dynamic> getRecommendedSettings(AssetUseCase useCase) {
    switch (useCase) {
      case AssetUseCase.thumbnail:
        return {
          'quality': 75,
          'maxWidth': 200,
          'maxHeight': 200,
          'format': CompressFormat.webp,
          'useSvgForIcons': true,
        };
      case AssetUseCase.listItem:
        return {
          'quality': 80,
          'maxWidth': 400,
          'maxHeight': 400,
          'format': CompressFormat.webp,
          'useSvgForIcons': true,
        };
      case AssetUseCase.fullscreen:
        return {
          'quality': 85,
          'maxWidth': 1080,
          'maxHeight': 1920,
          'format': CompressFormat.webp, // Changed from JPEG to WebP for better compression
          'useSvgForIcons': true,
        };
      case AssetUseCase.icon:
        return {
          'quality': 90,
          'maxWidth': 64,
          'maxHeight': 64,
          'format': CompressFormat.webp, // Changed from PNG to WebP for better compression
          'useSvgForIcons': true, // Prefer SVG for icons
        };
      case AssetUseCase.hdpi:
        return {
          'quality': 85,
          'maxWidth': 720,
          'maxHeight': 1280,
          'format': CompressFormat.webp,
          'useSvgForIcons': true,
        };
      case AssetUseCase.xhdpi:
        return {
          'quality': 85,
          'maxWidth': 1080,
          'maxHeight': 1920,
          'format': CompressFormat.webp,
          'useSvgForIcons': true,
        };
      case AssetUseCase.xxhdpi:
        return {
          'quality': 90,
          'maxWidth': 1440,
          'maxHeight': 2560,
          'format': CompressFormat.webp,
          'useSvgForIcons': true,
        };
    }
  }
  
  /// Batch compresses multiple assets
  static Future<Map<String, Uint8List?>> batchCompressAssets({
    required List<String> assetPaths,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    CompressFormat format = CompressFormat.webp, // Default to WebP for better compression
  }) async {
    final Map<String, Uint8List?> results = {};
    
    for (final assetPath in assetPaths) {
      results[assetPath] = await compressAsset(
        assetPath: assetPath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        format: format,
      );
    }
    
    return results;
  }
  
  /// Converts a PNG or JPG image to WebP format
  /// 
  /// Parameters:
  /// - file: The file to convert
  /// - quality: The quality of the WebP image (0-100)
  /// - lossless: Whether to use lossless compression
  static Future<File?> convertToWebP({
    required File file,
    int quality = 85,
    bool lossless = false,
  }) async {
    try {
      final String extension = path.extension(file.path).toLowerCase();
      if (extension != '.png' && extension != '.jpg' && extension != '.jpeg') {
        debugPrint('File is not a PNG or JPG image: ${file.path}');
        return null;
      }
      
      // Get a temporary file path
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${path.basenameWithoutExtension(file.path)}.webp',
      );
      
      // Compress the file to WebP
      final result = await compressor.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.webp,
      );
      
      if (result != null) {
        return File(result.path);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error converting to WebP: $e');
      return null;
    }
  }
  
  /// Generates multiple resolution variants of an image
  /// 
  /// Parameters:
  /// - file: The source image file
  /// - resolutions: List of resolution variants to generate
  /// - outputDir: Directory to save the variants
  /// - format: Format to save the variants in
  static Future<Map<AssetUseCase, File?>> generateResolutionVariants({
    required File file,
    List<AssetUseCase> resolutions = const [AssetUseCase.hdpi, AssetUseCase.xhdpi, AssetUseCase.xxhdpi],
    String? outputDir,
    CompressFormat format = CompressFormat.webp,
  }) async {
    final Map<AssetUseCase, File?> results = {};
    
    try {
      final String baseName = path.basenameWithoutExtension(file.path);
      final String extension = _getExtensionFromFormat(format);
      
      // Get output directory
      final Directory directory = outputDir != null 
          ? Directory(outputDir)
          : await getTemporaryDirectory();
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Generate each resolution variant
      for (final resolution in resolutions) {
        final settings = getRecommendedSettings(resolution);
        final int quality = settings['quality'] as int;
        final int? maxWidth = settings['maxWidth'] as int?;
        final int? maxHeight = settings['maxHeight'] as int?;
        
        final String variantName = '${baseName}_${resolution.toString().split('.').last}.$extension';
        final String targetPath = path.join(directory.path, variantName);
        
        final result = await compressor.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: quality,
          minWidth: maxWidth ?? 1,
          minHeight: maxHeight ?? 1,
          format: format,
        );
        
        if (result != null) {
          results[resolution] = File(result.path);
        } else {
          results[resolution] = null;
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error generating resolution variants: $e');
      return results;
    }
  }
}

/// Enum for different asset use cases
enum AssetUseCase {
  thumbnail,
  listItem,
  fullscreen,
  icon,
  hdpi,    // 720p resolution variant
  xhdpi,   // 1080p resolution variant
  xxhdpi,  // 1440p resolution variant
}

abstract class ImageCompressor {
  Future<Uint8List> compressWithList(
    Uint8List list,
    {int minWidth = 1,
    int minHeight = 1,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    bool autoCorrectionAngle = true});

  Future<File?> compressAndGetFile(
    String srcPath,
    String destPath,
    {int minWidth = 1,
    int minHeight = 1,
    int quality = 95,
    int rotate = 0,
    int numberOfRetries = 5,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    bool autoCorrectionAngle = true});
}

class RealImageCompressor implements ImageCompressor {
  @override
  Future<Uint8List> compressWithList(
    Uint8List list,
    {int minWidth = 1,
    int minHeight = 1,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    bool autoCorrectionAngle = true}) {
    return FlutterImageCompress.compressWithList(
      list,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      rotate: rotate,
      inSampleSize: inSampleSize,
      format: format,
      keepExif: keepExif,
      autoCorrectionAngle: autoCorrectionAngle,
    );
  }

  @override
  Future<File?> compressAndGetFile(
    String srcPath,
    String destPath,
    {int minWidth = 1,
    int minHeight = 1,
    int quality = 95,
    int rotate = 0,
    int numberOfRetries = 5,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    bool autoCorrectionAngle = true}) async {
    final xfile = await FlutterImageCompress.compressAndGetFile(
      srcPath,
      destPath,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      rotate: rotate,
      numberOfRetries: numberOfRetries,
      format: format,
      keepExif: keepExif,
      autoCorrectionAngle: autoCorrectionAngle,
    );
    return xfile != null ? File(xfile.path) : null;
  }
}