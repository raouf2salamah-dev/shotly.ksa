import 'dart:io'; 
import 'package:flutter/material.dart'; 
import '../deferred/video_player_helper.dart'; 
import '../deferred/video_player_shim.dart'; 
import '../utils/media_validator.dart'; 
import '../services/upload_flow_service.dart'; 

class MediaDemoScreen extends StatefulWidget { 
  const MediaDemoScreen({super.key}); 

  @override 
  State<MediaDemoScreen> createState() => _MediaDemoScreenState(); 
} 

class _MediaDemoScreenState extends State<MediaDemoScreen> { 
  File? _pickedImage; 
  File? _pickedVideo; 
  final _videoHelper = DeferredVideoController(); 
  late final UploadFlowService _uploadService; 
  
  @override
  void initState() {
    super.initState();
    _uploadService = UploadFlowService(MediaValidator());
  }

  @override 
  void dispose() { 
    _videoHelper.dispose(); 
    super.dispose(); 
  } 

  Future<void> _pickImage() async { 
    showDialog( 
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator()), 
    ); 
    try { 
      final result = await _uploadService.pickAndValidateImage();
      
      if (!result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Failed to pick image')),
          );
        }
        return;
      }
      
      setState(() => _pickedImage = result.file); 
    } catch (e) { 
      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar( 
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')), 
        ); 
      } 
    } finally { 
      if (mounted) Navigator.of(context).pop(); 
    } 
  } 

  Future<void> _pickVideo() async { 
    showDialog( 
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator()), 
    ); 
    try { 
      final result = await _uploadService.pickAndValidateVideo();
      
      if (!result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Failed to pick video')),
          );
        }
        return;
      }
      
      // Initialize video for playback
      final file = result.file!;
      final ok = await _videoHelper.initializeFromFile(file);
      if (!ok && mounted) { 
        ScaffoldMessenger.of(context).showSnackBar( 
          const SnackBar(content: Text('Failed to load video for playback')), 
        ); 
        return;
      }
      
      setState(() => _pickedVideo = file);
      await _videoHelper.play();
    } finally { 
      if (mounted) Navigator.of(context).pop(); 
      setState(() {}); 
    } 
  } 

  @override 
  Widget build(BuildContext context) { 
    final controller = _videoHelper.rawController; 

    return Scaffold( 
      appBar: AppBar(title: const Text('Deferred Media Demo')), 
      body: ListView( 
        padding: const EdgeInsets.all(16), 
        children: [ 
          ElevatedButton.icon( 
            onPressed: _pickImage, 
            icon: const Icon(Icons.image_outlined), 
            label: const Text('Pick Image (deferred)'), 
          ), 
          if (_pickedImage != null) 
            Padding( 
              padding: const EdgeInsets.only(top: 12), 
              child: Image.file(_pickedImage!, height: 160), 
            ), 
          const SizedBox(height: 20), 
          ElevatedButton.icon( 
            onPressed: _pickVideo, 
            icon: const Icon(Icons.video_collection_outlined), 
            label: const Text('Pick Video (deferred)'), 
          ), 
          if (controller != null && controller.value.isInitialized) 
            Padding( 
              padding: const EdgeInsets.only(top: 12), 
              child: AspectRatio( 
                aspectRatio: controller.value.aspectRatio, 
                child: DeferredVideoWidget(controller: controller), 
              ), 
            ), 
        ], 
      ), 
    ); 
  } 
}