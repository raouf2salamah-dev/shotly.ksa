import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../l10n/app_localizations.dart';

class UploadContentScreen extends StatefulWidget {
  const UploadContentScreen({super.key});

  @override
  State<UploadContentScreen> createState() => _UploadContentScreenState();
}

class _UploadContentScreenState extends State<UploadContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagsController = TextEditingController();
  
  File? _thumbnailFile;
  File? _contentFile;
  String? _thumbnailPath;
  String? _contentPath;
  ContentType _contentType = ContentType.image;
  String _selectedCategory = 'Photography';
  bool _isUploading = false;
  
  List<String> _categories = [
    'Photography',
    'Video',
    'GIF',
  ];
  
  @override
  void initState() {
    super.initState();
    // We'll update the categories with translated values when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _categories = [
          AppLocalizations.of(context)!.translate('photography'),
          AppLocalizations.of(context)!.translate('video'),
          AppLocalizations.of(context)!.translate('gif'),
        ];
        _selectedCategory = _categories[0];
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _thumbnailFile = File(image.path);
        _thumbnailPath = path.basename(image.path);
      });
    }
  }

  Future<void> _pickContent() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null) {
      File file = File(result.files.single.path!);
      String extension = path.extension(file.path).toLowerCase();
      
      // Determine content type based on file extension
      ContentType type;
      if (['.jpg', '.jpeg', '.png'].contains(extension)) {
        type = ContentType.image;
      } else if (extension == '.gif') {
        type = ContentType.gif;
      } else if (['.mp4', '.mov', '.avi'].contains(extension)) {
        type = ContentType.video;
      } else {
        // Default to image for unsupported types
        type = ContentType.image;
      }
      
      setState(() {
        _contentFile = file;
        _contentPath = path.basename(file.path);
        _contentType = type;
      });
    }
  }

  Future<void> _uploadContent() async {
    if (_formKey.currentState!.validate()) {
      if (_thumbnailFile == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('select_thumbnail_error'));
        return;
      }
      
      if (_contentFile == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('select_content_error'));
        return;
      }
      
      setState(() {
        _isUploading = true;
      });
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        
        if (user == null) {
          _showErrorSnackBar(AppLocalizations.of(context)!.translate('login_required'));
          setState(() {
            _isUploading = false;
          });
          return;
        }
        
        final contentService = ContentService();
        
        // Parse tags
        List<String> tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
        
        // Create content model
        final content = ContentModel(
          id: '', // Will be set by Firestore
          sellerId: user.uid,
          sellerName: user.displayName ?? '',
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          mediaUrl: '', // Will be set after upload
          thumbnailUrl: '', // Will be set after upload
          contentType: _contentType,
          tags: tags,
          category: _selectedCategory,
          createdAt: DateTime.now(),
          views: 0,
          downloads: 0,
          favorites: 0,
        );
        
        // Upload content and thumbnail
        await contentService.uploadContentWithFiles(
          mediaFile: _contentFile!,
          title: content.title,
          description: content.description,
          price: content.price,
          contentType: content.contentType,
          tags: content.tags,
          category: content.category,
        );
        
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('upload_success'))),
          );
          
          // Clear form
          _titleController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _tagsController.clear();
          setState(() {
            _thumbnailFile = null;
            _contentFile = null;
            _thumbnailPath = null;
            _contentPath = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          _showErrorSnackBar(AppLocalizations.of(context)!.translate('upload_error') + ': ${e.toString()}');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isUploading,
      loadingText: AppLocalizations.of(context)!.translate('uploading'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('upload_content')),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Upload
                Text(
                  AppLocalizations.of(context)!.translate('thumbnail_image'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickThumbnail,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _thumbnailFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _thumbnailFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate, size: 50),
                              const SizedBox(height: 8),
                              Text(AppLocalizations.of(context)!.translate('select_thumbnail')),
                            ],
                          ),
                  ),
                ),
                if (_thumbnailPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_thumbnailPath!),
                  ),
                
                const SizedBox(height: 24),
                
                // Content Upload
                Text(
                  AppLocalizations.of(context)!.translate('content_file'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickContent,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _contentFile != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          size: 40,
                          color: _contentFile != null
                              ? Colors.green
                              : Colors.grey[700],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _contentFile != null
                              ? AppLocalizations.of(context)!.translate('file_selected')
                              : AppLocalizations.of(context)!.translate('select_content_file'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_contentPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_contentPath!),
                  ),
                
                const SizedBox(height: 24),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('title'),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.translate('enter_title');
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('description'),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.translate('enter_description');
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('price'),
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.translate('enter_price');
                    }
                    try {
                      double.parse(value);
                    } catch (e) {
                      return AppLocalizations.of(context)!.translate('enter_valid_number');
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Category
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('category'),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Tags
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('tags'),
                    border: OutlineInputBorder(),
                    hintText: AppLocalizations.of(context)!.translate('tags_hint'),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _uploadContent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)!.translate('upload')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}