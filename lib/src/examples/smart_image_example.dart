import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../widgets/smart_image.dart';
import 'package:http/http.dart' as http;

class SmartImageExample extends StatefulWidget {
  const SmartImageExample({Key? key}) : super(key: key);

  @override
  State<SmartImageExample> createState() => _SmartImageExampleState();
}

class _SmartImageExampleState extends State<SmartImageExample> {
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebImageBytes();
    }
  }

  Future<void> _loadWebImageBytes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Example URL - replace with your actual image URL
      final response = await http.get(Uri.parse('https://picsum.photos/200'));
      
      if (response.statusCode == 200) {
        setState(() {
          _webImageBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load image: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading image: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Image Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Smart Image Widget Demo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red))
            else
              SmartImage(
                webImageUrl: 'https://example.com/image.png',
                assetImagePath: 'assets/images/placeholder.svg',
                localFilePath: '/storage/emulated/0/Download/my_image.png',
                webImageBytes: _webImageBytes,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                loadingWidget: const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
                errorBuilder: (context, error) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image, size: 50, color: Colors.red),
                    const SizedBox(height: 10),
                    Text('Error loading image: $error', 
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (kIsWeb && _webImageBytes == null && !_isLoading)
              ElevatedButton(
                onPressed: _loadWebImageBytes,
                child: const Text('Retry Loading Image'),
              ),
            const SizedBox(height: 20),
            const Text(
              'This widget automatically selects the appropriate image source based on platform.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'On Web: Uses Image.memory with webImageBytes when available, falls back to asset images.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}