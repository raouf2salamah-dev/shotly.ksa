import 'dart:io'; 
import 'package:flutter/material.dart'; 
import '../utils/media_validator.dart'; 
import '../services/upload_flow_service.dart'; 

class UploadScreen extends StatefulWidget { 
  const UploadScreen({super.key}); 

  @override 
  State<UploadScreen> createState() => _UploadScreenState(); 
} 

class _UploadScreenState extends State<UploadScreen> { 
  late final UploadFlowService _service; 
  File? _image; 
  File? _video; 

  @override 
  void initState() { 
    super.initState(); 

    // Toggle moderation off for zero cost: 
    final validator = MediaValidator( 
      // Set to null to skip moderation (no API calls, lowest cost) 
      detectPeopleOrAnimals: null, 
    ); 

    _service = UploadFlowService(validator); 
  } 

  Future<void> _pickImage() async { 
    _showLoading(); 
    final res = await _service.pickAndValidateImage(); 
    _hideLoading(); 

    if (!mounted) return; 
    if (res.isSuccess) { 
      setState(() => _image = res.file); 
      _toast("Image ready for upload."); 
    } else { 
      _toast(res.error!); 
    } 
  } 

  Future<void> _pickVideo() async { 
    _showLoading(); 
    final res = await _service.pickAndValidateVideo(); 
    _hideLoading(); 

    if (!mounted) return; 
    if (res.isSuccess) { 
      setState(() => _video = res.file); 
      _toast("Video ready for upload (≤ 1 min)."); 
    } else { 
      _toast(res.error!); 
    } 
  } 

  void _showLoading() { 
    showDialog( 
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator()), 
    ); 
  } 

  void _hideLoading() { 
    if (Navigator.canPop(context)) Navigator.pop(context); 
  } 

  void _toast(String msg) { 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); 
  } 

  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(title: const Text("Upload (Deferred + Validated)")), 
      body: ListView( 
        padding: const EdgeInsets.all(16), 
        children: [ 
          ElevatedButton.icon( 
            onPressed: _pickImage, 
            icon: const Icon(Icons.image_outlined), 
            label: const Text("Pick Image"), 
          ), 
          if (_image != null) ...[ 
            const SizedBox(height: 8), 
            Text("Selected image: ${_image!.path.split('/').last}"), 
          ], 
          const SizedBox(height: 24), 
          ElevatedButton.icon( 
            onPressed: _pickVideo, 
            icon: const Icon(Icons.video_file_outlined), 
            label: const Text("Pick Video (≤ 1 min)"), 
          ), 
          if (_video != null) ...[ 
            const SizedBox(height: 8), 
            Text("Selected video: ${_video!.path.split('/').last}"), 
          ], 
        ], 
      ), 
    ); 
  } 
}