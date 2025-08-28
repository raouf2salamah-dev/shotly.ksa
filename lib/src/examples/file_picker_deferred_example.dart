import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' deferred as file_picker;
import '../utils/deferred_loader.dart';

/// Example demonstrating how to use DeferredLoader with file_picker package
class DeferredFilePickerExample extends StatefulWidget {
  const DeferredFilePickerExample({super.key});

  @override
  State<DeferredFilePickerExample> createState() => _DeferredFilePickerExampleState();
}

class _DeferredFilePickerExampleState extends State<DeferredFilePickerExample> {
  bool _isLoading = false;
  String _status = 'Ready to pick file';
  String? _filePath;
  String? _fileName;
  
  // Create a loader for the file_picker library
  final _filePickerLoader = DeferredLoader(file_picker.loadLibrary);
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading file picker...';
    });
    
    try {
      // Ensure the library is loaded
      await _filePickerLoader.ensureLoaded();
      
      setState(() {
        _status = 'Selecting file...';
      });
      
      // Now we can use the file_picker
      final result = await file_picker.FilePicker.platform.pickFiles();
      
      if (result != null) {
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
          _status = 'File selected: $_fileName';
        });
      } else {
        setState(() {
          _status = 'No file selected';
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
      appBar: AppBar(title: const Text('Deferred File Picker Example')),
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
                onPressed: _pickFile,
                child: const Text('Pick File'),
              ),
            const SizedBox(height: 20),
            if (_filePath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Selected file: $_fileName'),
                    Text('Path: $_filePath', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}