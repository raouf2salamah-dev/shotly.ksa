import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';

class BundleDownloadExample extends StatefulWidget {
  const BundleDownloadExample({Key? key}) : super(key: key);

  @override
  _BundleDownloadExampleState createState() => _BundleDownloadExampleState();
}

class _BundleDownloadExampleState extends State<BundleDownloadExample> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _collectionController = TextEditingController(text: 'your-collection');
  final BundleService _bundleService = BundleService();
  bool _isLoading = false;
  String _status = '';
  int _downloadSize = 0;
  List<Map<String, dynamic>> _documents = [];
  bool _bundleLoaded = false;

  @override
  void dispose() {
    _urlController.dispose();
    _collectionController.dispose();
    super.dispose();
  }

  Future<void> _downloadAndLoadBundle() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _status = 'Please enter a valid bundle URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Downloading bundle...';
      _documents = [];
      _bundleLoaded = false;
    });

    try {
      // Download the bundle
      final bundleData = await _bundleService.downloadBundle(url);
      setState(() {
        _downloadSize = bundleData.length;
        _status = 'Bundle downloaded (${_downloadSize} bytes). Loading into Firestore...';
      });

      // Load the bundle into Firestore
      await _bundleService.loadBundle(bundleData);
      setState(() {
        _status = 'Bundle successfully loaded into Firestore!';
        _bundleLoaded = true;
      });
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

  Future<void> _readBundleData() async {
    final collectionPath = _collectionController.text.trim();
    if (collectionPath.isEmpty) {
      setState(() {
        _status = 'Please enter a valid collection path';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Reading data from collection: $collectionPath...';
      _documents = [];
    });

    try {
      // Read data from the bundle
      final snapshot = await _bundleService.readBundleData(collectionPath);
      
      // Process the documents
      final docs = <Map<String, dynamic>>[];
      _bundleService.processBundleDocuments(snapshot, (data) {
        docs.add(data);
      });
      
      setState(() {
        _documents = docs;
        _status = 'Successfully read ${docs.length} documents from cache';
      });
    } catch (e) {
      setState(() {
        _status = 'Error reading data: ${e.toString()}';
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
      appBar: AppBar(
        title: const Text('Firestore Bundle Example'),
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
                hintText: 'Enter the URL of the Firestore bundle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _downloadAndLoadBundle,
              child: _isLoading && !_bundleLoaded
                  ? const CircularProgressIndicator()
                  : const Text('Download & Load Bundle'),
            ),
            const SizedBox(height: 24),
            if (_bundleLoaded) ...[  
              TextField(
                controller: _collectionController,
                decoration: const InputDecoration(
                  labelText: 'Collection Path',
                  hintText: 'Enter the collection path to read from',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _readBundleData,
                child: _isLoading && _bundleLoaded
                    ? const CircularProgressIndicator()
                    : const Text('Read Bundle Data'),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_status),
            if (_downloadSize > 0) ...[  
              const SizedBox(height: 16),
              Text('Download size: $_downloadSize bytes'),
            ],
            if (_documents.isNotEmpty) ...[  
              const SizedBox(height: 16),
              const Text(
                'Documents:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          doc.toString(),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}