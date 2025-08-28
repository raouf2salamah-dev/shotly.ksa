import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/prompt_cache.dart';

class PromptCacheDemo extends StatefulWidget {
  const PromptCacheDemo({Key? key}) : super(key: key);

  @override
  State<PromptCacheDemo> createState() => _PromptCacheDemoState();
}

class _PromptCacheDemoState extends State<PromptCacheDemo> {
  final ApiService _apiService = ApiService();
  final List<String> _predefinedMediaTypes = ['image', 'video', 'gif'];
  final TextEditingController _customMediaTypeController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  
  String _selectedMediaType = 'image';
  List<String> _prompts = [];
  bool _loading = false;
  bool _isCustomMediaType = false;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }
  
  @override
  void dispose() {
    _customMediaTypeController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Cache Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Prompts',
            onPressed: _loading ? null : _refreshPrompts,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Cache',
            onPressed: _loading ? null : _clearCache,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Type Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Media Type:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _isCustomMediaType
                          ? TextField(
                              controller: _customMediaTypeController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter custom media type',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMediaType = value;
                                });
                              },
                            )
                          : DropdownButton<String>(
                              value: _selectedMediaType,
                              isExpanded: true,
                              items: _predefinedMediaTypes.map((String mediaType) {
                                return DropdownMenuItem<String>(
                                  value: mediaType,
                                  child: Text(mediaType),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedMediaType = newValue;
                                  });
                                  _loadPrompts();
                                }
                              },
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCustomMediaType = !_isCustomMediaType;
                      if (!_isCustomMediaType) {
                        _selectedMediaType = _predefinedMediaTypes.first;
                        _loadPrompts();
                      }
                    });
                  },
                  child: Text(_isCustomMediaType ? 'Use Preset' : 'Custom'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Add New Prompt
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'New Prompt',
                      hintText: 'Enter a new prompt',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _addPrompt,
                  child: const Text('Add'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Prompts List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cached Prompts (${_prompts.length}):',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _prompts.isEmpty
                  ? const Center(child: Text('No prompts available'))
                  : ListView.builder(
                      itemCount: _prompts.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(_prompts[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deletePrompt(index),
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

  Future<void> _loadPrompts() async {
    if (_selectedMediaType.isEmpty) return;
    
    setState(() {
      _loading = true;
    });

    try {
      final prompts = await _apiService.fetchPrompts(_selectedMediaType);
      setState(() {
        _prompts = prompts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading prompts: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _refreshPrompts() async {
    setState(() {
      _loading = true;
    });

    try {
      final prompts = await _apiService.refreshPrompts(_selectedMediaType);
      setState(() {
        _prompts = prompts;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompts refreshed from API')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing prompts: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _addPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }
    
    setState(() {
      _loading = true;
    });

    try {
      final prompts = await _apiService.addPrompt(_selectedMediaType, prompt);
      setState(() {
        _prompts = prompts;
        _promptController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding prompt: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _deletePrompt(int index) async {
    if (index < 0 || index >= _prompts.length) return;
    
    final promptToRemove = _prompts[index];
    final updatedPrompts = List<String>.from(_prompts);
    updatedPrompts.removeAt(index);
    
    setState(() {
      _loading = true;
    });

    try {
      await PromptCache.savePrompt(_selectedMediaType, updatedPrompts);
      setState(() {
        _prompts = updatedPrompts;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting prompt: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _clearCache() async {
    setState(() {
      _loading = true;
    });

    try {
      await PromptCache.clearPrompts(_selectedMediaType);
      setState(() {
        _prompts = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared for this media type')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}