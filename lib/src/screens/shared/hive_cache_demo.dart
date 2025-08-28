import 'package:flutter/material.dart';
import '../../services/hive_service.dart';
import '../../models/cache_item.dart';

class HiveCacheDemo extends StatefulWidget {
  const HiveCacheDemo({Key? key}) : super(key: key);

  @override
  State<HiveCacheDemo> createState() => _HiveCacheDemoState();
}

class _HiveCacheDemoState extends State<HiveCacheDemo> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  List<CacheItem> _cacheItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheItems();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadCacheItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = HiveService.getAllCacheItems();
      setState(() {
        _cacheItems = items;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cache items: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveItem() async {
    final key = _keyController.text.trim();
    final value = _valueController.text.trim();

    if (key.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key and value cannot be empty')),
      );
      return;
    }

    try {
      await HiveService.saveToCache(key, value);
      _keyController.clear();
      _valueController.clear();
      await _loadCacheItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item saved to cache')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item: $e')),
      );
    }
  }

  Future<void> _clearCache() async {
    try {
      await HiveService.clearCache();
      await _loadCacheItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive Cache Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheItems,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearCache,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Cache Item',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: 'Key',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveItem,
                      child: const Text('Save to Cache'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cached Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Cache items list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cacheItems.isEmpty
                      ? const Center(child: Text('No items in cache'))
                      : ListView.builder(
                          itemCount: _cacheItems.length,
                          itemBuilder: (context, index) {
                            final item = _cacheItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(item.key),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.value),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created: ${_formatDate(item.timestamp)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await HiveService.deleteFromCache(item.key);
                                    await _loadCacheItems();
                                  },
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}