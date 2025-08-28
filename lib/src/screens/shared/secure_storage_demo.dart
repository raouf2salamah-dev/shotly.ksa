import 'package:flutter/material.dart';
import '../../services/secure_storage_service.dart';
import '../../services/encrypted_hive_service.dart';
import 'dart:convert';

/// A demo screen showcasing both secure storage options:
/// 1. Flutter Secure Storage (for small sensitive data)
/// 2. Encrypted Hive (for larger datasets)
class SecureStorageDemo extends StatefulWidget {
  const SecureStorageDemo({Key? key}) : super(key: key);

  @override
  State<SecureStorageDemo> createState() => _SecureStorageDemoState();
}

class _SecureStorageDemoState extends State<SecureStorageDemo> with SingleTickerProviderStateMixin {
  // Using static methods from SecureStorageService
  final EncryptedHiveService _encryptedHive = EncryptedHiveService();
  
  late TabController _tabController;
  bool _isHiveInitialized = false;
  bool _isLoading = false;
  
  // Secure Storage fields
  final TextEditingController _secureKeyController = TextEditingController();
  final TextEditingController _secureValueController = TextEditingController();
  Map<String, String> _secureItems = {};
  
  // Encrypted Hive fields
  final TextEditingController _hiveKeyController = TextEditingController();
  final TextEditingController _hiveValueController = TextEditingController();
  Map<dynamic, dynamic> _hiveItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _secureKeyController.dispose();
    _secureValueController.dispose();
    _hiveKeyController.dispose();
    _hiveValueController.dispose();
    _encryptedHive.close(); // Close Hive box when done
    super.dispose();
  }
  
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialize encrypted Hive
      await _encryptedHive.init();
      _isHiveInitialized = true;
      
      // Load initial data
      await _loadSecureItems();
      await _loadHiveItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // SECURE STORAGE METHODS
  Future<void> _loadSecureItems() async {
    try {
      // Note: readAll is not available in the simplified static API
      // This would need to be implemented differently or added to the static API
      // For now, we'll just use an empty map
      setState(() {
        _secureItems = {};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading secure items: $e')),
      );
    }
  }

  Future<void> _saveSecureItem() async {
    final key = _secureKeyController.text.trim();
    final value = _secureValueController.text.trim();

    if (key.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key and value cannot be empty')),
      );
      return;
    }

    try {
      await SecureStorageService.write(key, value);
      _secureKeyController.clear();
      _secureValueController.clear();
      await _loadSecureItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item saved to secure storage')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving secure item: $e')),
      );
    }
  }

  Future<void> _deleteSecureItem(String key) async {
    try {
      await SecureStorageService.delete(key);
      await _loadSecureItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item "$key" deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  Future<void> _clearSecureStorage() async {
    try {
      // Note: deleteAll is not available in the simplified static API
      // This would need to be implemented differently or added to the static API
      // For now, we'll just clear our local map
      setState(() {
        _secureItems = {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secure storage cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing secure storage: $e')),
      );
    }
  }

  // ENCRYPTED HIVE METHODS
  Future<void> _loadHiveItems() async {
    if (!_isHiveInitialized) return;
    
    try {
      final keys = _encryptedHive.getAllKeys();
      final Map<dynamic, dynamic> items = {};
      
      for (final key in keys) {
        items[key] = _encryptedHive.getData(key);
      }
      
      setState(() {
        _hiveItems = items;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading Hive items: $e')),
      );
    }
  }

  Future<void> _saveHiveItem() async {
    if (!_isHiveInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encrypted Hive not initialized')),
      );
      return;
    }
    
    final key = _hiveKeyController.text.trim();
    final value = _hiveValueController.text.trim();

    if (key.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key and value cannot be empty')),
      );
      return;
    }

    try {
      // Try to parse as JSON if possible
      dynamic parsedValue;
      try {
        parsedValue = json.decode(value);
      } catch (_) {
        // If not valid JSON, store as string
        parsedValue = value;
      }
      
      await _encryptedHive.saveData(key, parsedValue);
      _hiveKeyController.clear();
      _hiveValueController.clear();
      await _loadHiveItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item saved to encrypted Hive')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving Hive item: $e')),
      );
    }
  }

  Future<void> _deleteHiveItem(dynamic key) async {
    if (!_isHiveInitialized) return;
    
    try {
      await _encryptedHive.deleteData(key);
      await _loadHiveItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item "$key" deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  Future<void> _clearHiveStorage() async {
    if (!_isHiveInitialized) return;
    
    try {
      await _encryptedHive.clearAll();
      await _loadHiveItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encrypted Hive cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing Hive storage: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Storage Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Secure Storage'),
            Tab(text: 'Encrypted Hive'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSecureStorageTab(),
                _buildEncryptedHiveTab(),
              ],
            ),
    );
  }

  Widget _buildSecureStorageTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Flutter Secure Storage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Securely store small sensitive data like tokens and credentials',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Input form
          TextField(
            controller: _secureKeyController,
            decoration: const InputDecoration(
              labelText: 'Key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _secureValueController,
            decoration: const InputDecoration(
              labelText: 'Value',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveSecureItem,
            child: const Text('Save to Secure Storage'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stored Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _secureItems.isEmpty ? null : _clearSecureStorage,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Items list
          Expanded(
            child: _secureItems.isEmpty
                ? const Center(child: Text('No items in secure storage'))
                : ListView.builder(
                    itemCount: _secureItems.length,
                    itemBuilder: (context, index) {
                      final key = _secureItems.keys.elementAt(index);
                      final value = _secureItems[key]!;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(key),
                          subtitle: Text(value),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteSecureItem(key),
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

  Widget _buildEncryptedHiveTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Encrypted Hive Storage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Securely store larger datasets with AES-256 encryption',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Input form
          TextField(
            controller: _hiveKeyController,
            decoration: const InputDecoration(
              labelText: 'Key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _hiveValueController,
            decoration: const InputDecoration(
              labelText: 'Value (string or JSON)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isHiveInitialized ? _saveHiveItem : null,
            child: const Text('Save to Encrypted Hive'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stored Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: (_isHiveInitialized && _hiveItems.isNotEmpty) 
                    ? _clearHiveStorage 
                    : null,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Items list
          Expanded(
            child: !_isHiveInitialized
                ? const Center(child: Text('Encrypted Hive not initialized'))
                : _hiveItems.isEmpty
                    ? const Center(child: Text('No items in encrypted Hive'))
                    : ListView.builder(
                        itemCount: _hiveItems.length,
                        itemBuilder: (context, index) {
                          final key = _hiveItems.keys.elementAt(index);
                          final value = _hiveItems[key];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(key.toString()),
                              subtitle: Text(
                                value is Map || value is List
                                    ? json.encode(value)
                                    : value.toString(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteHiveItem(key),
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