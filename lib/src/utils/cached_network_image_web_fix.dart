import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// This class is a custom implementation to fix the cached_network_image_web package issue
/// It provides the missing createImageCodecFromUrl method
class ImageLoader {
  /// Create an image codec from a URL
  static Future<ui.Codec> createImageCodecFromUrl(
    String url, {
    double? scale,
    bool? allowUpscaling,
  }) async {
    // This is a workaround for the missing method in cached_network_image_web
    // In a real app, you would implement this properly
    final completer = Completer<ui.Codec>();
    
    // Create a network image and get its codec
    final image = NetworkImage(url);
    final imageStream = image.resolve(const ImageConfiguration());
    
    final listener = ImageStreamListener((info, _) {
      completer.complete(info.codec);
    }, onError: (exception, stackTrace) {
      completer.completeError(exception, stackTrace);
    });
    
    imageStream.addListener(listener);
    
    return completer.future;
  }
}