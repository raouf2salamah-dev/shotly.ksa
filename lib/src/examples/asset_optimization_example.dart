import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/asset_optimizer.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AssetOptimizationExample extends StatefulWidget {
  const AssetOptimizationExample({super.key});

  @override
  State<AssetOptimizationExample> createState() => _AssetOptimizationExampleState();
}

class _AssetOptimizationExampleState extends State<AssetOptimizationExample> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _optimizationResults = [];
  
  @override
  void initState() {
    super.initState();
  }
  
  // Demonstrate different asset optimization techniques
  Future<void> _optimizeAssets() async {
    setState(() {
      _isLoading = true;
      _optimizationResults = [];
    });
    
    try {
      // 1. Compress a thumbnail image using WebP format
      final thumbnailSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.thumbnail);
      final thumbnailResult = await AssetOptimizer.compressAsset(
        assetPath: 'assets/images/sample_large.jpg',
        quality: thumbnailSettings['quality'] as int,
        maxWidth: thumbnailSettings['maxWidth'] as int,
        maxHeight: thumbnailSettings['maxHeight'] as int,
        format: thumbnailSettings['format'] as CompressFormat,
      );
      
      if (thumbnailResult != null) {
        _addResult('Thumbnail (WebP)', 'assets/images/sample_large.jpg', thumbnailResult);
      }
      
      // 2. Compress a list item image
      final listItemSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.listItem);
      final listItemResult = await AssetOptimizer.compressAsset(
        assetPath: 'assets/images/sample_large.jpg',
        quality: listItemSettings['quality'] as int,
        maxWidth: listItemSettings['maxWidth'] as int,
        maxHeight: listItemSettings['maxHeight'] as int,
        format: listItemSettings['format'] as CompressFormat,
      );
      
      if (listItemResult != null) {
        _addResult('List Item (WebP)', 'assets/images/sample_large.jpg', listItemResult);
      }
      
      // 3. Compress a fullscreen image using JPEG format
      final fullscreenSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.fullscreen);
      final fullscreenResult = await AssetOptimizer.compressAsset(
        assetPath: 'assets/images/sample_large.jpg',
        quality: fullscreenSettings['quality'] as int,
        maxWidth: fullscreenSettings['maxWidth'] as int,
        maxHeight: fullscreenSettings['maxHeight'] as int,
        format: fullscreenSettings['format'] as CompressFormat,
      );
      
      if (fullscreenResult != null) {
        _addResult('Fullscreen (JPEG)', 'assets/images/sample_large.jpg', fullscreenResult);
      }
      
      // 4. Compress an icon using PNG format
      final iconSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.icon);
      final iconResult = await AssetOptimizer.compressAsset(
        assetPath: 'assets/images/sample_icon.png',
        quality: iconSettings['quality'] as int,
        maxWidth: iconSettings['maxWidth'] as int,
        maxHeight: iconSettings['maxHeight'] as int,
        format: iconSettings['format'] as CompressFormat,
      );
      
      if (iconResult != null) {
        _addResult('Icon (PNG)', 'assets/images/sample_icon.png', iconResult);
      }
      
      // 5. Batch compress multiple assets
      final batchResults = await AssetOptimizer.batchCompressAssets(
        assetPaths: [
          'assets/images/sample1.jpg',
          'assets/images/sample2.jpg',
          'assets/images/sample3.jpg',
        ],
        quality: 80,
        maxWidth: 800,
        maxHeight: 600,
        format: CompressFormat.webp,
      );
      
      batchResults.forEach((assetPath, result) {
        if (result != null) {
          _addResult('Batch (WebP)', assetPath, result);
        }
      });
      
    } catch (e) {
      debugPrint('Error optimizing assets: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Add a result to the list
  void _addResult(String type, String assetPath, Uint8List compressedData) {
    setState(() {
      _optimizationResults.add({
        'type': type,
        'assetPath': assetPath,
        'originalSize': 0, // Will be populated
        'compressedSize': compressedData.length,
        'compressedData': compressedData,
      });
    });
    
    // Get original size asynchronously
    _getOriginalSize(assetPath).then((originalSize) {
      if (originalSize != null) {
        setState(() {
          final index = _optimizationResults.indexWhere((result) => 
              result['type'] == type && result['assetPath'] == assetPath);
          
          if (index != -1) {
            _optimizationResults[index]['originalSize'] = originalSize;
          }
        });
      }
    });
  }
  
  // Get the original size of an asset
  Future<int?> _getOriginalSize(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.lengthInBytes;
    } catch (e) {
      debugPrint('Error getting original size: $e');
      return null;
    }
  }
  
  // Calculate compression ratio
  String _getCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 'N/A';
    final ratio = (1 - (compressedSize / originalSize)) * 100;
    return '${ratio.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Optimization Example'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _optimizeAssets,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Optimize Assets'),
            ),
          ),
          Expanded(
            child: _optimizationResults.isEmpty
                ? const Center(
                    child: Text('Press the button to optimize assets'),
                  )
                : ListView.builder(
                    itemCount: _optimizationResults.length,
                    itemBuilder: (context, index) {
                      final result = _optimizationResults[index];
                      final originalSize = result['originalSize'] as int;
                      final compressedSize = result['compressedSize'] as int;
                      
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result['type'] as String,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8.0),
                              Text('Asset: ${result['assetPath']}'),
                              const SizedBox(height: 4.0),
                              Text(
                                'Original Size: ${(originalSize / 1024).toStringAsFixed(2)} KB',
                              ),
                              Text(
                                'Compressed Size: ${(compressedSize / 1024).toStringAsFixed(2)} KB',
                              ),
                              Text(
                                'Compression Ratio: ${_getCompressionRatio(originalSize, compressedSize)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              if (result['compressedData'] != null)
                                SizedBox(
                                  height: 100,
                                  child: Image.memory(
                                    result['compressedData'] as Uint8List,
                                    fit: BoxFit.contain,
                                  ),
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
    );
  }
}