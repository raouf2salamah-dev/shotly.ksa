import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' deferred as http;
import 'package:image/image.dart' deferred as img;
import 'package:video_player/video_player.dart' deferred as video_player;
import '../utils/deferred_loader.dart';

/// A utility class that validates media files using deferred loading
/// to optimize app performance by loading heavy dependencies only when needed
class DeferredMediaValidator {
  // Create loaders for each deferred library
  static final _httpLoader = DeferredLoader(http.loadLibrary);
  static final _imageLoader = DeferredLoader(img.loadLibrary);
  static final _videoPlayerLoader = DeferredLoader(video_player.loadLibrary);
  
  // Constants for validation
  static const int maxImageSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int maxVideoSizeBytes = 15 * 1024 * 1024; // 15MB
  static const int maxImageDimension = 1920; // 1920px
  static const int maxVideoDuration = 60; // 60 seconds
  
  /// Validates an image file
  static Future<ValidationResult> validateImage(File file) async {
    // Check file size first (doesn't require deferred libraries)
    final fileSize = await file.length();
    if (fileSize > maxImageSizeBytes) {
      return ValidationResult.error(
        'Image size exceeds the maximum allowed size of 2MB.'
      );
    }
    
    try {
      // Load the image processing library
      await _imageLoader.ensureLoaded();
      
      // Read and decode the image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return ValidationResult.error('Invalid image format.');
      }
      
      // Check dimensions
      if (image.width > maxImageDimension || image.height > maxImageDimension) {
        return ValidationResult.error(
          'Image dimensions exceed the maximum allowed size of 1920px.'
        );
      }
      
      // Optional: Check for faces or other content
      final hasFace = await _detectFaces(bytes);
      if (!hasFace) {
        return ValidationResult.warning(
          'No faces detected in the image. Images with faces perform better.'
        );
      }
      
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Error validating image: ${e.toString()}');
    }
  }
  
  /// Validates a video file
  static Future<ValidationResult> validateVideo(File file) async {
    // Check file size first (doesn't require deferred libraries)
    final fileSize = await file.length();
    if (fileSize > maxVideoSizeBytes) {
      return ValidationResult.error(
        'Video size exceeds the maximum allowed size of 15MB.'
      );
    }
    
    try {
      // Load the video player library
      await _videoPlayerLoader.ensureLoaded();
      
      // Initialize video player
      final controller = video_player.VideoPlayerController.file(file);
      await controller.initialize();
      
      // Check duration
      final duration = controller.value.duration;
      if (duration.inSeconds > maxVideoDuration) {
        // Clean up resources
        await controller.dispose();
        
        return ValidationResult.error(
          'Video duration exceeds the maximum allowed duration of 1 minute.'
        );
      }
      
      // Clean up resources
      await controller.dispose();
      
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Error validating video: ${e.toString()}');
    }
  }
  
  /// Detects faces in an image using a remote API
  static Future<bool> _detectFaces(Uint8List imageBytes) async {
    try {
      // Load the HTTP library
      await _httpLoader.ensureLoaded();
      
      // This is a placeholder for actual face detection API call
      // In a real implementation, you would call a service like Google Vision API
      // or a local ML model
      
      // Simulated API call
      final response = await http.post(
        Uri.parse('https://api.huggingface.co/models/face-detection'),
        body: imageBytes,
        headers: {'Authorization': 'Bearer your_api_key_here'},
      );
      
      // Parse response (simplified)
      return response.statusCode == 200;
    } catch (e) {
      // If face detection fails, we'll just return true to not block the upload
      return true;
    }
  }
}

/// Result of media validation
class ValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  
  ValidationResult({required this.isValid, this.hasWarning = false, this.message});
  
  factory ValidationResult.success() {
    return ValidationResult(isValid: true);
  }
  
  factory ValidationResult.warning(String message) {
    return ValidationResult(isValid: true, hasWarning: true, message: message);
  }
  
  factory ValidationResult.error(String message) {
    return ValidationResult(isValid: false, message: message);
  }
}

/// Example widget that demonstrates using the DeferredMediaValidator
class MediaValidationExample extends StatefulWidget {
  const MediaValidationExample({super.key});

  @override
  State<MediaValidationExample> createState() => _MediaValidationExampleState();
}

class _MediaValidationExampleState extends State<MediaValidationExample> {
  File? _selectedFile;
  bool _isValidating = false;
  ValidationResult? _validationResult;
  
  Future<void> _validateImage() async {
    // Simulate selecting a file
    // In a real app, you would use image_picker or file_picker
    final file = File('/path/to/image.jpg'); // Placeholder
    
    setState(() {
      _selectedFile = file;
      _isValidating = true;
      _validationResult = null;
    });
    
    final result = await DeferredMediaValidator.validateImage(file);
    
    setState(() {
      _isValidating = false;
      _validationResult = result;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Validation Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isValidating)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _validateImage,
                child: const Text('Validate Image'),
              ),
            
            const SizedBox(height: 20),
            
            if (_validationResult != null) ...[              
              Icon(
                _validationResult!.isValid 
                    ? Icons.check_circle 
                    : Icons.error,
                color: _validationResult!.isValid 
                    ? (_validationResult!.hasWarning ? Colors.orange : Colors.green)
                    : Colors.red,
                size: 48,
              ),
              
              if (_validationResult!.message != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _validationResult!.message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _validationResult!.isValid 
                          ? (_validationResult!.hasWarning ? Colors.orange : Colors.green)
                          : Colors.red,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}