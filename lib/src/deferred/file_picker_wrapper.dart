import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' deferred as file_picker;
import '../utils/deferred_loader.dart';

/// A utility class that provides deferred loading for the file_picker package
/// to optimize app performance by loading heavy dependencies only when needed.
class DeferredFilePicker {
  // Create a loader for the file_picker library
  static final _filePickerLoader = DeferredLoader(file_picker.loadLibrary);
  
  /// Picks a single file with deferred loading
  /// 
  /// [type] - The type of file to pick (defaults to any)
  /// [allowedExtensions] - List of allowed extensions when type is custom
  /// [allowCompression] - Whether to allow compression of the picked file
  /// [timeout] - Optional timeout for loading the library
  static Future<File?> pickSingleFile({
    dynamic type,
    List<String>? allowedExtensions,
    bool allowCompression = true,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      // Ensure the library is loaded with timeout
      await _filePickerLoader.ensureLoaded(timeout: timeout);
      
      // Now we can use the file_picker
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? file_picker.FileType.custom : file_picker.FileType.any,
        allowedExtensions: allowedExtensions,
        allowCompression: allowCompression,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          return File(path);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      rethrow;
    }
    
    return null;
  }
  
  /// Picks multiple files with deferred loading
  /// 
  /// [type] - The type of files to pick (defaults to any)
  /// [allowedExtensions] - List of allowed extensions when type is custom
  /// [allowCompression] - Whether to allow compression of the picked files
  /// [timeout] - Optional timeout for loading the library
  static Future<List<File>> pickMultipleFiles({
    dynamic type,
    List<String>? allowedExtensions,
    bool allowCompression = true,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      // Ensure the library is loaded with timeout
      await _filePickerLoader.ensureLoaded(timeout: timeout);
      
      // Now we can use the file_picker
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? file_picker.FileType.custom : file_picker.FileType.any,
        allowedExtensions: allowedExtensions,
        allowCompression: allowCompression,
        allowMultiple: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final files = <File>[];
        for (final file in result.files) {
          final path = file.path;
          if (path != null) {
            files.add(File(path));
          }
        }
        return files;
      }
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
      rethrow;
    }
    
    return [];
  }
}