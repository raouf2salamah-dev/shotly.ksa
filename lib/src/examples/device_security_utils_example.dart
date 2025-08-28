import 'package:flutter/material.dart';
import '../security/device_security_utils.dart';

/// Example showing how to use DeviceSecurityUtils to check device integrity
/// and restrict features in a simple way
class DeviceSecurityUtilsExample extends StatefulWidget {
  const DeviceSecurityUtilsExample({Key? key}) : super(key: key);

  @override
  State<DeviceSecurityUtilsExample> createState() => _DeviceSecurityUtilsExampleState();
}

class _DeviceSecurityUtilsExampleState extends State<DeviceSecurityUtilsExample> {
  bool _uploadsEnabled = true;
  bool _paymentsEnabled = true;
  bool _isChecking = false;
  bool? _isDeviceCompromised;

  @override
  void initState() {
    super.initState();
    _checkDeviceSecurity();
  }

  Future<void> _checkDeviceSecurity() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Use the utility function to check device integrity and show warning
      final isCompromised = await DeviceSecurityUtils.checkDeviceIntegrityAndWarn(
        context: context,
        // Custom warning message
        message: 'This device appears to be compromised. For security reasons, '
            'uploads and payments have been disabled.',
        // Callback to restrict features when device is compromised
        onCompromisedDevice: () {
          setState(() {
            _uploadsEnabled = false;
            _paymentsEnabled = false;
          });
        },
      );

      if (mounted) {
        setState(() {
          _isDeviceCompromised = isCompromised;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking device security: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Utils Example'),
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  if (_isDeviceCompromised != null)
                    Card(
                      color: _isDeviceCompromised! 
                          ? Colors.red.shade100 
                          : Colors.green.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              _isDeviceCompromised! 
                                  ? Icons.warning_amber_rounded 
                                  : Icons.security,
                              color: _isDeviceCompromised! 
                                  ? Colors.red 
                                  : Colors.green,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _isDeviceCompromised!
                                    ? 'Device is compromised - features restricted'
                                    : 'Device is secure - all features available',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Feature status
                  const Text(
                    'Feature Status:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureStatus(
                    'Upload Files', 
                    _uploadsEnabled,
                    Icons.cloud_upload,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildFeatureStatus(
                    'Make Payments', 
                    _paymentsEnabled,
                    Icons.payment,
                  ),
                  
                  const Spacer(),
                  
                  // Check again button
                  Center(
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkDeviceSecurity,
                      child: const Text('Check Device Security Again'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureStatus(String featureName, bool isEnabled, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: isEnabled ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 16),
        Text(
          featureName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              color: isEnabled ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}