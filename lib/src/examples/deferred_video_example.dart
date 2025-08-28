import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/content_preview_widget.dart';

/// Example demonstrating how to use deferred loading for video playback
class DeferredVideoExample extends StatefulWidget {
  const DeferredVideoExample({super.key});

  @override
  State<DeferredVideoExample> createState() => _DeferredVideoExampleState();
}

class _DeferredVideoExampleState extends State<DeferredVideoExample> {
  bool _isLoading = false;
  String _status = 'Ready to play';
  VideoPlayerController? _controller;
  
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _controller?.dispose();
    super.dispose();
  }
  
  Future<void> _playVideo() async {
    final videoUrl = 'https://example.com/sample-video.mp4';
    
    setState(() {
      _isLoading = true;
      _status = 'Loading video player...';
    });
    
    try {
      // Use the static method from ContentPreviewWidget
      _controller = await ContentPreviewWidget.playVideoDeferredLoading(videoUrl);
      
      setState(() {
        _status = 'Video player initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deferred Video Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _playVideo,
                child: const Text('Play Video'),
              ),
          ],
        ),
      ),
    );
  }
}