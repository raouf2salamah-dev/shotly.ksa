import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/document.dart';
import '../services/sync_service.dart';

class SyncDemoScreen extends StatefulWidget {
  const SyncDemoScreen({super.key});

  @override
  State<SyncDemoScreen> createState() => _SyncDemoScreenState();
}

class _SyncDemoScreenState extends State<SyncDemoScreen> {
  final SyncService _syncService = SyncService();
  List<Document> _documents = [];
  bool _isLoading = false;
  String _collection = 'users';
  String _statusMessage = '';
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _syncService.connectivityStream.listen((ConnectivityResult result) {
      setState(() {
        _statusMessage = result != ConnectivityResult.none 
            ? 'Online - Using real-time data' 
            : 'Offline - Using cached data';
      });
    });
  }

  Future<void> _checkConnectivity() async {
    setState(() {
      _statusMessage = _syncService.isOnline 
          ? 'Online - Using real-time data' 
          : 'Offline - Using cached data';
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading data...';
    });

    try {
      final documents = await _syncService.getData(_collection);
      setState(() {
        _documents = documents;
        _isLoading = false;
        _statusMessage = _syncService.isOnline 
            ? 'Online - Loaded ${documents.length} documents' 
            : 'Offline - Loaded ${documents.length} documents from cache';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _forceSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing data...';
    });

    try {
      await _syncService.syncDataWhenOnline();
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sync completed successfully';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sync error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Service Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceSync,
            tooltip: 'Force Sync',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: _syncService.isOnline ? Colors.green.shade100 : Colors.orange.shade100,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  _syncService.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _syncService.isOnline ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _syncService.isOnline ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Collection selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Collection: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _collection,
                  items: const [
                    DropdownMenuItem(value: 'users', child: Text('Users')),
                    DropdownMenuItem(value: 'content', child: Text('Content')),
                    DropdownMenuItem(value: 'settings', child: Text('Settings')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _collection = value;
                      });
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Load Data'),
                ),
              ],
            ),
          ),
          
          // Data display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? const Center(child: Text('No data available'))
                    : ListView.builder(
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final document = _documents[index];
                          return ListTile(
                            title: Text(document.id),
                            subtitle: Text('Updated: ${document.updatedAt.toString().substring(0, 16)}'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              _showDocumentDetails(document);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDocumentDetails(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document: ${document.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Collection: ${document.collection}'),
              Text('Updated: ${document.updatedAt}'),
              const Divider(),
              const Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...document.data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${entry.key}: ${entry.value}'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}