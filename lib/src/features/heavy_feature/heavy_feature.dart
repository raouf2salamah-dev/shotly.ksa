import 'package:flutter/material.dart';

/// A heavy feature module that should be loaded using deferred loading
/// to improve initial app load time and reduce memory usage until needed.
class HeavyFeature {
  /// Singleton instance
  static final HeavyFeature _instance = HeavyFeature._internal();
  
  /// Factory constructor to return the singleton instance
  factory HeavyFeature() => _instance;
  
  /// Internal constructor
  HeavyFeature._internal();
  
  /// Flag to track if the feature has been initialized
  bool _isInitialized = false;
  
  /// Check if the feature is initialized
  bool get isInitialized => _isInitialized;
  
  /// Initialize the heavy feature
  /// This should be called after the library is loaded
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Simulate heavy initialization work
    await Future.delayed(const Duration(seconds: 1));
    
    debugPrint('HeavyFeature: Initialized successfully');
    _isInitialized = true;
  }
  
  /// Start the heavy feature
  /// This is the main entry point after loading the library
  void start() {
    if (!_isInitialized) {
      debugPrint('HeavyFeature: Warning - feature not initialized');
      initialize();
    }
    
    debugPrint('HeavyFeature: Started');
    // Add your heavy feature implementation here
  }
  
  /// Example method that performs a heavy computation
  Future<List<Map<String, dynamic>>> generateComplexData(int count) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Simulate complex data generation
    final result = <Map<String, dynamic>>[];
    
    for (var i = 0; i < count; i++) {
      result.add({
        'id': 'item_$i',
        'title': 'Heavy Feature Item $i',
        'complexity': i * 1000,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': List.generate(100, (index) => 'Data point $index for item $i'),
      });
      
      // Simulate heavy processing
      if (i % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    
    return result;
  }
  
  /// Example UI widget that can be used after loading
  Widget buildFeatureUI() {
    return const HeavyFeatureWidget();
  }
}

/// A widget that demonstrates the heavy feature
class HeavyFeatureWidget extends StatefulWidget {
  const HeavyFeatureWidget({super.key});

  @override
  State<HeavyFeatureWidget> createState() => _HeavyFeatureWidgetState();
}

class _HeavyFeatureWidgetState extends State<HeavyFeatureWidget> {
  final HeavyFeature _feature = HeavyFeature();
  List<Map<String, dynamic>>? _data;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = await _feature.generateComplexData(20);
      
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading heavy feature data: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heavy Feature'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('No data available'))
              : ListView.builder(
                  itemCount: _data!.length,
                  itemBuilder: (context, index) {
                    final item = _data![index];
                    return ListTile(
                      title: Text(item['title'] as String),
                      subtitle: Text('Complexity: ${item['complexity']}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Handle item tap
                      },
                    );
                  },
                ),
    );
  }
}