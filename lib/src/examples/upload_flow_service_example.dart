import 'dart:io';
import 'package:flutter/material.dart';
import '../services/upload_flow_service.dart';
import '../utils/media_validator.dart';
import '../deferred/video_player_helper.dart';
import '../deferred/video_player_shim.dart';

class UploadFlowExample extends StatefulWidget {
  const UploadFlowExample({super.key});

  @override
  State<UploadFlowExample> createState() => _UploadFlowExampleState();
}

class _UploadFlowExampleState extends State<UploadFlowExample> {
  late final UploadFlowService _uploadService;
  File? _selectedImage;
  File? _selectedVideo;
  final _videoHelper = DeferredVideoController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the upload service with a MediaValidator
    _uploadService = UploadFlowService(MediaValidator());
  }

  @override
  void dispose() {
    _videoHelper.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _uploadService.pickAndValidateImage();
      
      if (result.isSuccess) {
        setState(() => _selectedImage = result.file);
      } else if (mounted) {
        _showError(result.error ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVideoUpload() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _uploadService.pickAndValidateVideo();
      
      if (result.isSuccess) {
        final file = result.file!;
        setState(() => _selectedVideo = file);
        
        // Initialize for playback
        final ok = await _videoHelper.initializeFromFile(file);
        if (!ok && mounted) {
          _showError('Failed to initialize video for playback');
        } else {
          await _videoHelper.play();
        }
      } else if (mounted) {
        _showError(result.error ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoHelper.rawController;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Flow Example')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Image section
              Text('Image Upload', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _handleImageUpload,
                icon: const Icon(Icons.image),
                label: const Text('Select Image'),
              ),
              if (_selectedImage != null) ...[  
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              
              const Divider(height: 40),
              
              // Video section
              Text('Video Upload', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _handleVideoUpload,
                icon: const Icon(Icons.video_library),
                label: const Text('Select Video'),
              ),
              if (controller != null && controller.value.isInitialized) ...[  
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: DeferredVideoWidget(controller: controller),
                  ),
                ),
              ],
            ],
          ),
    );
  }
}