import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' deferred as image_picker;
import '../utils/deferred_loader.dart';

/// A utility class that provides deferred loading for the image_picker package
/// to optimize app performance by loading heavy dependencies only when needed.
class DeferredImagePicker {
  // Create a loader for the image_picker library
  static final _imagePickerLoader = DeferredLoader(image_picker.loadLibrary);
  
  /// Picks an image from the gallery with deferred loading
  /// 
  /// [imageQuality] - The quality of the resulting image, from 0-100
  /// [maxWidth] - The maximum width of the image (defaults to 1920)
  /// [maxHeight] - The maximum height of the image (defaults to 1920)
  /// [timeout] - Optional timeout for loading the library
  static Future<File?> pickImageFromGallery({
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      // Ensure the library is loaded with timeout
      await _imagePickerLoader.ensureLoaded(timeout: timeout);
      
      // Now we can use the image_picker
      final pickedFile = await image_picker.ImagePicker().pickImage(
        source: image_picker.ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
    
    return null;
  }
  
  /// Picks an image from the camera with deferred loading
  /// 
  /// [imageQuality] - The quality of the resulting image, from 0-100
  /// [maxWidth] - The maximum width of the image (defaults to 1920)
  /// [maxHeight] - The maximum height of the image (defaults to 1920)
  /// [timeout] - Optional timeout for loading the library
  static Future<File?> pickImageFromCamera({
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      // Ensure the library is loaded with timeout
      await _imagePickerLoader.ensureLoaded(timeout: timeout);
      
      // Now we can use the image_picker
      final pickedFile = await image_picker.ImagePicker().pickImage(
        source: image_picker.ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
    
    return null;
  }
}