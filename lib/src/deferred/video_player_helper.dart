import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' deferred as vplayer;
import '../utils/deferred_loader.dart';

/// A utility class that provides deferred loading for the video_player package
/// to optimize app performance by loading heavy dependencies only when needed.
class DeferredVideoController {
  // Create a loader for the video_player library
  final _videoPlayerLoader = DeferredLoader(vplayer.loadLibrary);
  
  // We can't use the deferred type in a declaration
  // So we use dynamic and cast when needed
  dynamic _controller;
  bool _isInitialized = false;
  
  /// Returns the raw video player controller
  /// Note: This will be null until initializeFromFile is called
  dynamic get rawController => _controller;
  
  /// Returns whether the controller is initialized
  bool get isInitialized => _isInitialized;
  
  /// Initializes the video controller from a file with deferred loading
  /// 
  /// [file] - The video file to play
  /// [timeout] - Optional timeout for loading the library
  /// Returns true if initialization was successful, false otherwise
  Future<bool> initializeFromFile(
    File file, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      // Ensure the library is loaded with timeout
      await _videoPlayerLoader.ensureLoaded(timeout: timeout);
      
      // Create the controller
      _controller = vplayer.VideoPlayerController.file(file);
      
      // Initialize the controller
      await _controller.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      _isInitialized = false;
      return false;
    }
  }
  
  /// Initializes the video controller from a network URL with deferred loading
  /// 
  /// [url] - The video URL to play
  /// [timeout] - Optional timeout for loading the library
  /// Returns true if initialization was successful, false otherwise
  Future<bool> initializeFromNetwork(
    String url, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      // Ensure the library is loaded with timeout
      await _videoPlayerLoader.ensureLoaded(timeout: timeout);
      
      // Create the controller
      _controller = vplayer.VideoPlayerController.network(url);
      
      // Initialize the controller
      await _controller.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      _isInitialized = false;
      return false;
    }
  }
  
  /// Plays the video if controller is initialized
  Future<void> play() async {
    if (_controller != null && _isInitialized) {
      await _controller.play();
    }
  }
  
  /// Pauses the video if controller is initialized
  Future<void> pause() async {
    if (_controller != null && _isInitialized) {
      await _controller.pause();
    }
  }
  
  /// Disposes the controller and resources
  void dispose() {
    if (_controller != null) {
      _controller.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }
}