import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class BundleDownloadExample extends StatefulWidget {
  const BundleDownloadExample({Key? key}) : super(key: key);

  @override
  State<BundleDownloadExample> createState() => _BundleDownloadExampleState();
}

class _BundleDownloadExampleState extends State<BundleDownloadExample> {
  final BundleService _bundleService = BundleService();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _status = '';
  int _downloadedBytes = 0;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _downloadBundle() async {
    final bundleUrl = _urlController.text.trim();
    if (bundleUrl.isEmpty) {
      setState(() {
        _status = 'Please enter a valid URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Downloading...';
    });

    try {
      // Replace with your bundle's URL
      final buffer = await _bundleService.downloadBundle(bundleUrl);
      
      setState(() {
        _isLoading = false;
        _downloadedBytes = buffer.length;
        _status = 'Download complete: ${buffer.length} bytes';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bundle Download Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Bundle URL',
                hintText: 'https://your-site-url.com/bundles/your-bundle-id',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _downloadBundle,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Download Bundle'),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_downloadedBytes > 0) ...[  
              const SizedBox(height: 16),
              Text(
                'Downloaded: $_downloadedBytes bytes',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}