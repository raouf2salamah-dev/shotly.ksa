import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/asset_optimizer.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:file_picker/file_picker.dart';

class WebpConversionExample extends StatefulWidget {
  const WebpConversionExample({super.key});

  @override
  State<WebpConversionExample> createState() => _WebpConversionExampleState();
}

class _WebpConversionExampleState extends State<WebpConversionExample> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _conversionResults = [];
  Map<AssetUseCase, File?> _resolutionVariants = {};
  
  @override
  void initState() {
    super.initState();
  }
  
  // Pick and convert an image to WebP
  Future<void> _pickAndConvertImage() async {
    setState(() {
      _isLoading = true;
      _conversionResults = [];
    });
    
    try {
      // Pick an image file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final file = File(result.files.first.path!);
      final fileSize = await file.length();
      
      // Convert to WebP with lossy compression
      final lossyWebp = await AssetOptimizer.convertToWebP(
        file: file,
        quality: 85,
        lossless: false,
      );
      
      if (lossyWebp != null) {
        final lossySize = await lossyWebp.length();
        _addResult('Lossy WebP', file.path, lossyWebp, fileSize, lossySize);
      }
      
      // Convert to WebP with lossless compression (better for images with text or sharp edges)
      final losslessWebp = await AssetOptimizer.convertToWebP(
        file: file,
        quality: 100,
        lossless: true,
      );
      
      if (losslessWebp != null) {
        final losslessSize = await losslessWebp.length();
        _addResult('Lossless WebP', file.path, losslessWebp, fileSize, losslessSize);
      }
      
      // Generate multiple resolution variants
      _resolutionVariants = await AssetOptimizer.generateResolutionVariants(
        file: file,
        resolutions: [AssetUseCase.hdpi, AssetUseCase.xhdpi, AssetUseCase.xxhdpi],
      );
      
      // Add resolution variants to results
      for (final entry in _resolutionVariants.entries) {
        if (entry.value != null) {
          final variantSize = await entry.value!.length();
          _addResult(
            '${entry.key.toString().split('.').last} Resolution', 
            file.path, 
            entry.value!, 
            fileSize, 
            variantSize
          );
        }
      }
      
    } catch (e) {
      debugPrint('Error converting image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addResult(String type, String originalPath, File resultFile, int originalSize, int newSize) {
    setState(() {
      _conversionResults.add({
        'type': type,
        'originalPath': originalPath,
        'resultPath': resultFile.path,
        'originalSize': originalSize,
        'newSize': newSize,
        'compressionRatio': originalSize > 0 ? (originalSize / newSize).toStringAsFixed(2) : 'N/A',
        'file': resultFile,
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebP Conversion Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Convert PNG/JPG to WebP & Generate Multiple Resolutions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _pickAndConvertImage,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Pick & Convert Image'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Conversion Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _conversionResults.isEmpty
                  ? const Center(child: Text('No conversions yet'))
                  : ListView.builder(
                      itemCount: _conversionResults.length,
                      itemBuilder: (context, index) {
                        final result = _conversionResults[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result['type'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Original Size:'),
                                          Text('${(result['originalSize'] / 1024).toStringAsFixed(2)} KB'),
                                          const SizedBox(height: 8),
                                          const Text('New Size:'),
                                          Text('${(result['newSize'] / 1024).toStringAsFixed(2)} KB'),
                                          const SizedBox(height: 8),
                                          const Text('Compression Ratio:'),
                                          Text('${result['compressionRatio']}x'),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: result['file'] != null
                                          ? Image.file(
                                              result['file'],
                                              height: 100,
                                              fit: BoxFit.contain,
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}