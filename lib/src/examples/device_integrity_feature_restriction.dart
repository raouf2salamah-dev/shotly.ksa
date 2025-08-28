import 'package:flutter/material.dart';
import '../security/device_integrity.dart';

/// Example screen demonstrating how to use DeviceIntegrity to restrict features
class DeviceIntegrityFeatureRestriction extends StatefulWidget {
  const DeviceIntegrityFeatureRestriction({Key? key}) : super(key: key);

  @override
  State<DeviceIntegrityFeatureRestriction> createState() => _DeviceIntegrityFeatureRestrictionState();
}

class _DeviceIntegrityFeatureRestrictionState extends State<DeviceIntegrityFeatureRestriction> {
  bool _isDeviceCompromised = false;
  bool _isLoading = true;
  
  // Feature flags that can be toggled based on device integrity
  bool _allowUploads = true;
  bool _allowPayments = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceIntegrity();
  }

  Future<void> _checkDeviceIntegrity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if device is compromised
      final isCompromised = await DeviceIntegrity.isCompromised();
      
      if (mounted) {
        setState(() {
          _isDeviceCompromised = isCompromised;
          _isLoading = false;
          
          // Restrict features if device is compromised
          if (isCompromised) {
            _allowUploads = false;
            _allowPayments = false;
            
            // Show warning dialog
            _showSecurityWarning();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Default to restricting features if we can't determine device integrity
          _allowUploads = false;
          _allowPayments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking device integrity: $e')),
        );
      }
    }
  }

  void _showSecurityWarning() {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Security Warning'),
            content: const Text(
              'This device appears to be jailbroken/rooted or has developer mode enabled, '
              'which may compromise the security of your data. Some features have been '
              'restricted for your protection.\n\nFor full functionality, please use a '
              'non-compromised device.'
            ),
            actions: [
              TextButton(
                child: const Text('I Understand'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Restrictions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device status
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _isDeviceCompromised ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: _isDeviceCompromised ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isDeviceCompromised 
                              ? Icons.warning_amber_rounded 
                              : Icons.verified_user,
                          color: _isDeviceCompromised ? Colors.red : Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _isDeviceCompromised
                                ? 'Device compromised - Features restricted'
                                : 'Device secure - All features available',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isDeviceCompromised ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Available Features',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Upload feature
                  FeatureItem(
                    icon: Icons.cloud_upload,
                    title: 'Upload Content',
                    isEnabled: _allowUploads,
                    onTap: _allowUploads
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Upload feature accessed')),
                            );
                          }
                        : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment feature
                  FeatureItem(
                    icon: Icons.payment,
                    title: 'Make Payment',
                    isEnabled: _allowPayments,
                    onTap: _allowPayments
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment feature accessed')),
                            );
                          }
                        : null,
                  ),
                  
                  const Spacer(),
                  
                  // Check again button
                  Center(
                    child: ElevatedButton(
                      onPressed: _checkDeviceIntegrity,
                      child: const Text('Check Device Again'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Widget representing a feature item with enabled/disabled state
class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isEnabled;
  final VoidCallback? onTap;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.isEnabled,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEnabled ? Theme.of(context).primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            Icon(
              isEnabled ? Icons.check_circle : Icons.block,
              color: isEnabled ? Colors.green : Colors.red,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}