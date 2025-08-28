import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' deferred as video_player;

/// This example demonstrates how to properly implement deferred loading
/// for the video_player package in a real-world scenario.
class DeferredVideoPlayerExample extends StatefulWidget {
  final String videoUrl;
  
  const DeferredVideoPlayerExample({
    super.key,
    required this.videoUrl,
  });

  @override
  State<DeferredVideoPlayerExample> createState() => _DeferredVideoPlayerExampleState();
}

class _DeferredVideoPlayerExampleState extends State<DeferredVideoPlayerExample> {
  // We can't use the deferred type in a declaration
  // So we use dynamic and cast when needed
  dynamic _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Load the deferred library
      await video_player.loadLibrary();
      
      // Now we can create the controller
      _controller = video_player.VideoPlayerController.network(widget.videoUrl);
      
      // Initialize the controller
      await _controller.initialize();
      
      // Start playback
      await _controller.play();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources
    if (_controller != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    
    if (_isInitialized) {
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: video_player.VideoPlayer(_controller),
      );
    }
    
    return const Center(child: Text('Failed to initialize video player'));
  }
}

/// Usage example:
/// 
/// ```dart
/// DeferredVideoPlayerExample(
///   videoUrl: 'https://example.com/video.mp4',
/// )
/// ```