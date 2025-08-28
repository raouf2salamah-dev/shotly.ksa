import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/simple_cache_service.dart';

class SimpleCacheDemo extends StatefulWidget {
  const SimpleCacheDemo({Key? key}) : super(key: key);

  @override
  State<SimpleCacheDemo> createState() => _SimpleCacheDemoState();
}

class _SimpleCacheDemoState extends State<SimpleCacheDemo> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final SimpleCacheService _cacheService = SimpleCacheService(maxItems: 50);
  Map<String, dynamic> _cacheItems = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initCache();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _initCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cacheService.init();
      await _loadCacheItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing cache: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCacheItems() async {
    // This is a simplified approach to show all cache items
    // In a real app, you might want to store a list of keys separately
    final box = await Hive.openBox('simple_cache'); // Using the same box name as in SimpleCacheService
    final Map<String, dynamic> items = {};
    
    for (final key in box.keys) {
      final value = _cacheService.get(key.toString());
      if (value != null) {
        items[key.toString()] = value;
      }
    }
    
    setState(() {
      _cacheItems = items;
    });
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
      await _cacheService.save(key, value);
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
      await _cacheService.clear();
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

  Future<void> _addMultipleItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add multiple items to demonstrate auto-purging
      for (int i = 0; i < 10; i++) {
        final key = 'test_key_${DateTime.now().millisecondsSinceEpoch}_$i';
        final value = 'Test value $i generated at ${DateTime.now().toString()}';
        await _cacheService.save(key, value);
      }
      await _loadCacheItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added 10 test items to cache')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding test items: $e')),
      );
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
        title: const Text('Simple Cache Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addMultipleItems,
            tooltip: 'Add 10 test items',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCache,
            tooltip: 'Clear all cache',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheItems,
            tooltip: 'Refresh cache items',
          ),
        ],
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: 'Key',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cached Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_cacheItems.length} / ${_cacheService.maxItems}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _cacheItems.length > _cacheService.maxItems * 0.8
                        ? Colors.orange
                        : Colors.grey[600],
                  ),
                ),
              ],
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
                            final key = _cacheItems.keys.elementAt(index);
                            final value = _cacheItems[key];
                            // We'll display the value without the timestamp
                            // since we can't use async in itemBuilder
                            
                            // We can't access timestamp anymore, so we'll skip the expiration calculation
                            final timeLeft = null;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(key),
                                    subtitle: Text(value.toString()),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        await _cacheService.delete(key);
                                        await _loadCacheItems();
                                      },
                                    ),
                                  ),
                                  if (timeLeft != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.timer_outlined,
                                            size: 14,
                                            color: timeLeft.inHours < 1 ? Colors.red : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Expires in: ${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: timeLeft.inHours < 1 ? Colors.red : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
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