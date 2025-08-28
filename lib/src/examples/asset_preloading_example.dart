import 'package:flutter/material.dart';
import '../services/asset_preloading_service.dart';
import '../widgets/smart_image.dart';
import 'dart:typed_data';

class AssetPreloadingExample extends StatefulWidget {
  const AssetPreloadingExample({Key? key}) : super(key: key);

  @override
  State<AssetPreloadingExample> createState() => _AssetPreloadingExampleState();
}

class _AssetPreloadingExampleState extends State<AssetPreloadingExample> {
  final AssetPreloadingService _preloadingService = AssetPreloadingService();
  final List<String> _essentialAssets = [
    'assets/images/placeholder.svg',
    'assets/images/placeholder2.svg',
    'assets/images/start.svg',
    'assets/images/ai.svg',
  ];
  
  Map<String, bool> _preloadStatus = {};
  Map<String, Uint8List?> _preloadedAssets = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPreloadStatus();
  }

  void _checkPreloadStatus() {
    setState(() {
      for (final asset in _essentialAssets) {
        _preloadStatus[asset] = _preloadingService.isAssetPreloaded(asset);
        _preloadedAssets[asset] = _preloadingService.getPreloadedAsset(asset);
      }
    });
  }

  Future<void> _preloadAssets() async {
    setState(() {
      _isLoading = true;
    });

    await _preloadingService.preloadEssentialAssets();
    
    setState(() {
      _isLoading = false;
      _checkPreloadStatus();
    });
  }

  Future<void> _clearPreloadedAssets() async {
    _preloadingService.clearPreloadedAssets();
    _checkPreloadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Preloading Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Essential Assets Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._essentialAssets.map((asset) => _buildAssetStatusRow(asset)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _preloadAssets,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Preload Assets'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearPreloadedAssets,
                  child: const Text('Clear Preloaded Assets'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'SmartImage Widget Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: _essentialAssets.map((asset) => _buildSmartImageDemo(asset)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetStatusRow(String asset) {
    final isPreloaded = _preloadStatus[asset] ?? false;
    final preloadedAsset = _preloadedAssets[asset];
    final assetSize = preloadedAsset?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isPreloaded ? Icons.check_circle : Icons.cancel,
            color: isPreloaded ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              asset,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          Text(
            isPreloaded ? '${(assetSize / 1024).toStringAsFixed(1)} KB' : 'Not loaded',
            style: TextStyle(
              color: isPreloaded ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartImageDemo(String asset) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: SmartImage(
              assetImagePath: asset,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              asset.split('/').last,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}