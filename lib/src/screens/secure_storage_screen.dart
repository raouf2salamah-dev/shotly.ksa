import 'package:flutter/material.dart';
import 'shared/secure_storage_demo.dart';
import '../services/secure_storage_service.dart';
import '../services/encrypted_hive_service.dart';
import '../services/hive_service.dart';
import '../models/secure_user_data.dart';

/// Main screen for accessing secure storage features and demos
class SecureStorageScreen extends StatefulWidget {
  const SecureStorageScreen({Key? key}) : super(key: key);

  @override
  State<SecureStorageScreen> createState() => _SecureStorageScreenState();
}

class _SecureStorageScreenState extends State<SecureStorageScreen> {
  bool _isInitializing = true;
  String _statusMessage = 'Initializing services...';
  bool _servicesReady = false;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // Initialize Hive Service (for regular caching)
      await HiveService.init();
      setState(() {
        _statusMessage = 'Regular Hive initialized';
      });
      
      // Initialize Encrypted Hive Service
      final encryptedHive = EncryptedHiveService();
      await encryptedHive.init();
      setState(() {
        _statusMessage = 'Encrypted Hive initialized';
      });
      
      // Initialize SecureUserData (combines both storage options)
      final secureUserData = SecureUserData();
      await secureUserData.init();
      
      setState(() {
        _statusMessage = 'All services initialized successfully';
        _servicesReady = true;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing services: $e';
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Storage'),
      ),
      body: _isInitializing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              ),
            )
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Secure Storage Options',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _servicesReady
                ? 'All secure storage services are initialized and ready to use'
                : 'Some services failed to initialize. See error message below.',
            style: TextStyle(
              color: _servicesReady ? Colors.green : Colors.red,
            ),
          ),
          if (!_servicesReady)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Available Demos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            title: 'Secure Storage Demo',
            description: 'Interactive demo of both flutter_secure_storage and encrypted Hive',
            icon: Icons.security,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecureStorageDemo(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            title: 'Documentation',
            description: 'View comprehensive guide on secure storage options',
            icon: Icons.description,
            onTap: () {
              // Show a dialog with documentation info
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Secure Storage Documentation'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'The secure storage documentation is available in the project at:\n\n'
                      'lib/src/docs/secure_storage_guide.md\n\n'
                      'This guide covers:\n'
                      '• Flutter Secure Storage implementation\n'
                      '• Encrypted Hive implementation\n'
                      '• Comparison of storage options\n'
                      '• Best practices for secure data handling\n'
                      '• Implementation examples',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            title: 'Security Check',
            description: 'Verify that secure storage is working correctly',
            icon: Icons.verified_user,
            onTap: () async {
              // Perform a quick test of secure storage
              final testKey = 'security_test_key';
              final testValue = 'test_value_${DateTime.now().millisecondsSinceEpoch}';
              
              try {
                // Write test value
                await SecureStorageService.write(testKey, testValue);
                
                // Read test value
                final retrievedValue = await SecureStorageService.read(testKey);
                
                // Delete test value
                await SecureStorageService.delete(testKey);
                
                // Show result
                if (retrievedValue == testValue) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Security check passed! Secure storage is working correctly.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Security check failed! Retrieved value did not match.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Security check error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _servicesReady ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 48,
                color: _servicesReady ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: _servicesReady ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: _servicesReady ? null : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}