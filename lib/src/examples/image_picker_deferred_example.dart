import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' deferred as image_picker;
import '../utils/deferred_loader.dart';

/// Example demonstrating how to use DeferredLoader with image_picker package
class DeferredImagePickerExample extends StatefulWidget {
  const DeferredImagePickerExample({super.key});

  @override
  State<DeferredImagePickerExample> createState() => _DeferredImagePickerExampleState();
}

class _DeferredImagePickerExampleState extends State<DeferredImagePickerExample> {
  bool _isLoading = false;
  String _status = 'Ready to pick image';
  File? _imageFile;
  
  // Create a loader for the image_picker library
  final _imagePickerLoader = DeferredLoader(image_picker.loadLibrary);
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading image picker...';
    });
    
    try {
      // Ensure the library is loaded
      await _imagePickerLoader.ensureLoaded();
      
      setState(() {
        _status = 'Selecting image...';
      });
      
      // Now we can use the image_picker
      final pickedFile = await image_picker.ImagePicker().pickImage(
        source: image_picker.ImageSource.gallery,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _status = 'Image selected successfully!';
        });
      } else {
        setState(() {
          _status = 'No image selected';
        });
      }
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
      appBar: AppBar(title: const Text('Deferred Image Picker Example')),
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
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
            const SizedBox(height: 20),
            if (_imageFile != null)
              SizedBox(
                height: 200,
                width: 200,
                child: Image.file(_imageFile!),
              ),
          ],
        ),
      ),
    );
  }
}