import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
// For deferred loading example
import 'package:video_player/video_player.dart' deferred as video_player_deferred;

import '../models/content_model.dart';

class ContentPreviewWidget extends StatefulWidget {
  final ContentModel content;
  
  const ContentPreviewWidget({
    super.key,
    required this.content,
  });

  @override
  State<ContentPreviewWidget> createState() => _ContentPreviewWidgetState();
}

class _ContentPreviewWidgetState extends State<ContentPreviewWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.content.contentType == ContentType.video) {
      _initializeVideoPlayer();
    }
  }
  
  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.content.mediaUrl);
    await _videoController!.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Error: $errorMessage',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.content.contentType) {
      case ContentType.image:
        return _buildImagePreview();
      case ContentType.gif:
        return _buildImagePreview(); // Use the same preview for GIFs as images
      case ContentType.video:
        return _buildVideoPreview();
      default:
        return _buildImagePreview(); // Default to image preview
    }
  }
  
  Widget _buildImagePreview() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: widget.content.mediaUrl.isNotEmpty
            ? widget.content.mediaUrl
            : widget.content.thumbnailUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error, size: 50),
        ),
      ),
    );
  }
  
  Widget _buildVideoPreview() {
    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: widget.content.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.black,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black,
                child: const Icon(Icons.error, color: Colors.white, size: 50),
              ),
            ),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }
    
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
  
  // Audio, document, and generic preview methods removed as part of content type simplification
  
  /// Example of how to use deferred loading for video playback
  /// This can be called from outside the widget to play a video URL
  static Future<VideoPlayerController> playVideo(String url, {bool autoPlay = true}) async {
    // Create and initialize the controller
    final controller = VideoPlayerController.network(url);
    await controller.initialize();
    
    // Start playback if requested
    if (autoPlay) {
      await controller.play();
    }
    
    // Return the controller so the caller can dispose it when done
    return controller;
  }
  
  /// Example of how to use deferred loading for video playback
  /// This demonstrates proper deferred loading pattern
  static Future<VideoPlayerController> playVideoDeferredLoading(String url, {bool autoPlay = true}) async {
    // Load the deferred library first
    await video_player_deferred.loadLibrary();
    
    // Create and initialize the controller
    final controller = video_player_deferred.VideoPlayerController.network(url);
    await controller.initialize();
    
    // Start playback if requested
    if (autoPlay) {
      await controller.play();
    }
    
    // Return the controller so the caller can dispose it when done
    return controller;
  }
}