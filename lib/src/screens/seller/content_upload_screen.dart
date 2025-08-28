import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ContentUploadScreen extends StatefulWidget {
  const ContentUploadScreen({super.key});

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  ContentType _selectedContentType = ContentType.image;
  File? _mediaFile;
  String? _mediaPath;
  bool _isUploading = false;
  
  // Video player controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  
  Future<void> _pickMedia(ImageSource source) async {
    try {
      final picker = ImagePicker();
      XFile? pickedFile;
      
      if (_selectedContentType == ContentType.image) {
        pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 80,
        );
      } else if (_selectedContentType == ContentType.video) {
        pickedFile = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 5),
        );
      } else if (_selectedContentType == ContentType.audio) {
        // For audio, we'll use file picker in a future implementation
        // For now, show a message that this feature is coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio upload coming soon!'))
        );
        return;
      } else if (_selectedContentType == ContentType.document || _selectedContentType == ContentType.other) {
        // For documents and other types, we'll use file picker in a future implementation
        // For now, show a message that this feature is coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document and other file types upload coming soon!'))
        );
        return;
      }
      
      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          _mediaPath = pickedFile.path;
        });
        
        // Initialize video player if video
        if (_selectedContentType == ContentType.video) {
          _initializeVideoPlayer();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: ${e.toString()}'))
      );
    }
  }
  
  Future<void> _initializeVideoPlayer() async {
    if (_mediaFile == null) return;
    
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    
    _videoPlayerController = VideoPlayerController.file(_mediaFile!);
    await _videoPlayerController!.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
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
      setState(() {});
    }
  }
  
  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select media to upload'))
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      await contentService.uploadContent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        contentType: _selectedContentType,
        mediaFile: _mediaFile!,
      );
      
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content uploaded successfully!'))
        );
        
        context.go('/seller');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Content Type Selection
                Text(
                  'Content Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildContentTypeSelector(),
                const SizedBox(height: 24.0),
                
                // Media Upload
                Text(
                  'Upload Media',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildMediaUploader(),
                const SizedBox(height: 24.0),
                
                // Content Details
                Text(
                  'Content Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // Title
                CustomTextField(
                  controller: _titleController,
                  hintText: 'Title',
                  prefixIcon: Icons.title,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                
                // Description
                CustomTextField(
                  controller: _descriptionController,
                  hintText: 'Description',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                
                // Price
                CustomTextField(
                  controller: _priceController,
                  hintText: 'Price',
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Price must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),
                
                // Upload Button
                CustomButton(
                  text: 'Upload Content',
                  icon: Icons.cloud_upload,
                  isLoading: _isUploading,
                  onPressed: _handleUpload,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContentTypeSelector() {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildContentTypeOption(
          type: ContentType.image,
          icon: Icons.image,
          label: 'Image',
        ),
        _buildContentTypeOption(
          type: ContentType.video,
          icon: Icons.videocam,
          label: 'Video',
        ),
        _buildContentTypeOption(
          type: ContentType.audio,
          icon: Icons.audiotrack,
          label: 'Audio',
        ),
        _buildContentTypeOption(
          type: ContentType.document,
          icon: Icons.insert_drive_file,
          label: 'Document',
        ),
        _buildContentTypeOption(
          type: ContentType.other,
          icon: Icons.more_horiz,
          label: 'Other',
        ),
      ],
    );
  }
  
  Widget _buildContentTypeOption({
    required ContentType type,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedContentType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContentType = type;
          _mediaFile = null;
          _mediaPath = null;
          _videoPlayerController?.dispose();
          _chewieController?.dispose();
          _videoPlayerController = null;
          _chewieController = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.brightness == Brightness.light
                  ? Colors.grey.shade100
                  : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.brightness == Brightness.light
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32.0,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMediaUploader() {
    final theme = Theme.of(context);
    
    return Container(
      height: 240.0,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.grey.shade100
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade300
              : Colors.grey.shade700,
        ),
      ),
      child: _mediaFile == null
          ? _buildMediaPlaceholder()
          : _buildMediaPreview(),
    );
  }
  
  Widget _buildMediaPlaceholder() {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getContentTypeIcon(),
          size: 64.0,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Tap to upload ${_selectedContentType.name}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickMedia(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 16.0),
            ElevatedButton.icon(
              onPressed: () => _pickMedia(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMediaPreview() {
    final theme = Theme.of(context);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media Preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: _selectedContentType == ContentType.video
              ? _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator())
              : Image.file(
                  _mediaFile!,
                  fit: BoxFit.cover,
                ),
        ),
        
        // Remove Button
        Positioned(
          top: 8.0,
          right: 8.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _mediaFile = null;
                  _mediaPath = null;
                  _videoPlayerController?.dispose();
                  _chewieController?.dispose();
                  _videoPlayerController = null;
                  _chewieController = null;
                });
              },
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getContentTypeIcon() {
    switch (_selectedContentType) {
      case ContentType.image:
        return Icons.image;
      case ContentType.video:
        return Icons.videocam;
      case ContentType.audio:
        return Icons.audiotrack;
      case ContentType.document:
        return Icons.insert_drive_file;
      case ContentType.other:
        return Icons.file_present;
    }
  }
}