import 'package:flutter/material.dart';
import '../security/device_integrity.dart';

/// Example screen demonstrating the use of DeviceIntegrity
class DeviceIntegrityExample extends StatefulWidget {
  const DeviceIntegrityExample({Key? key}) : super(key: key);

  @override
  State<DeviceIntegrityExample> createState() => _DeviceIntegrityExampleState();
}

class _DeviceIntegrityExampleState extends State<DeviceIntegrityExample> {
  bool? _isDeviceCompromised;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceIntegrity();
  }

  Future<void> _checkDeviceIntegrity() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final isCompromised = await DeviceIntegrity.isCompromised();
      
      if (mounted) {
        setState(() {
          _isDeviceCompromised = isCompromised;
          _isChecking = false;
        });
        
        // Show warning if device is compromised
        if (isCompromised) {
          _showSecurityWarning();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
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
              'which may compromise the security of your data. Using this app on a '
              'compromised device is not recommended.\n\nProceed at your own risk.'
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
        title: const Text('Device Integrity Check'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isChecking)
              const CircularProgressIndicator()
            else if (_isDeviceCompromised != null)
              Icon(
                _isDeviceCompromised! 
                  ? Icons.warning_amber_rounded 
                  : Icons.verified_user,
                color: _isDeviceCompromised! ? Colors.red : Colors.green,
                size: 80,
              ),
            const SizedBox(height: 20),
            Text(
              _isChecking 
                ? 'Checking device integrity...'
                : _isDeviceCompromised == null
                  ? 'Unable to determine device integrity'
                  : _isDeviceCompromised!
                    ? 'Device integrity compromised!'
                    : 'Device integrity verified',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkDeviceIntegrity,
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}