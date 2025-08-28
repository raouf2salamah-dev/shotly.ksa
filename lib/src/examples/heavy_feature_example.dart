import 'package:flutter/material.dart';
import '../features/heavy_feature/heavy_feature.dart' deferred as heavy_feature;

/// Example demonstrating how to use deferred loading for a heavy feature
class HeavyFeatureExample extends StatefulWidget {
  const HeavyFeatureExample({super.key});

  @override
  State<HeavyFeatureExample> createState() => _HeavyFeatureExampleState();
}

class _HeavyFeatureExampleState extends State<HeavyFeatureExample> {
  bool _isLoading = false;
  bool _isLoaded = false;
  String _status = 'Ready to load';
  
  @override
  void initState() {
    super.initState();
  }
  
  /// Load the heavy feature module
  Future<void> _loadFeature() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading heavy feature module...';
    });
    
    try {
      // Load the deferred library
      await heavy_feature.loadLibrary();
      
      // Initialize the feature
      await heavy_feature.HeavyFeature().initialize();
      
      setState(() {
        _isLoaded = true;
        _status = 'Heavy feature module loaded successfully!';
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
  
  /// Start the heavy feature
  void _startFeature() {
    if (!_isLoaded) {
      setState(() {
        _status = 'Error: Feature not loaded yet';
      });
      return;
    }
    
    // Start the feature
    heavy_feature.HeavyFeature().start();
    
    // Navigate to the heavy feature UI
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _HeavyFeatureScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heavy Feature Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (!_isLoaded)
                ElevatedButton(
                  onPressed: _loadFeature,
                  child: const Text('Load Heavy Feature'),
                )
              else
                ElevatedButton(
                  onPressed: _startFeature,
                  child: const Text('Start Heavy Feature'),
                ),
              const SizedBox(height: 24),
              Text(
                'This example demonstrates deferred loading of a heavy feature module. '
                'The module is only loaded when explicitly requested, saving memory and '
                'improving initial app load time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wrapper screen that displays the heavy feature UI
class _HeavyFeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return heavy_feature.HeavyFeature().buildFeatureUI();
  }
}