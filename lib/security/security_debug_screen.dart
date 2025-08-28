import 'package:flutter/material.dart';
import 'device_integrity_service.dart';
import 'security_logger.dart';

/// A debug screen that displays the results of device integrity checks
/// Useful for testing and verifying security features
class SecurityDebugScreen extends StatefulWidget {
  const SecurityDebugScreen({super.key});

  @override
  State<SecurityDebugScreen> createState() => _SecurityDebugScreenState();
}

class _SecurityDebugScreenState extends State<SecurityDebugScreen> {
  DeviceIntegrityResult? result;

  @override
  void initState() {
    super.initState();
    _checkDeviceIntegrity();
  }
  
  Future<void> _checkDeviceIntegrity() async {
    SecurityLogger.log('SecurityDebugScreen', detail: 'Running integrity checks');
    final r = await DeviceIntegrityService.check();
    SecurityLogger.log('SecurityDebugCheck', 
      detail: 'compromised=${r.compromised}, '
              'jailbroken=${r.isJailbrokenOrRooted}, '
              'emulator=${!r.isRealDevice}, '
              'devMode=${r.developerMode}, '
              'mockLocation=${r.canMockLocation}');
    
    if (mounted) {
      setState(() => result = r);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Debug')),
      body: result == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text('Compromised'),
                  subtitle: Text(result!.compromised.toString()),
                  trailing: Icon(
                    result!.compromised ? Icons.warning : Icons.check_circle,
                    color: result!.compromised ? Colors.red : Colors.green,
                  ),
                ),
                ListTile(
                  title: const Text('Jailbroken/Rooted'),
                  subtitle: Text(result!.isJailbrokenOrRooted.toString()),
                  trailing: Icon(
                    result!.isJailbrokenOrRooted ? Icons.warning : Icons.check_circle,
                    color: result!.isJailbrokenOrRooted ? Colors.red : Colors.green,
                  ),
                ),
                ListTile(
                  title: const Text('Real Device'),
                  subtitle: Text(result!.isRealDevice.toString()),
                  trailing: Icon(
                    result!.isRealDevice ? Icons.check_circle : Icons.warning,
                    color: result!.isRealDevice ? Colors.green : Colors.orange,
                  ),
                ),
                ListTile(
                  title: const Text('Developer Mode'),
                  subtitle: Text(result!.developerMode.toString()),
                  trailing: Icon(
                    result!.developerMode ? Icons.warning : Icons.check_circle,
                    color: result!.developerMode ? Colors.orange : Colors.green,
                  ),
                ),
                ListTile(
                  title: const Text('Mock Location Allowed'),
                  subtitle: Text(result!.canMockLocation.toString()),
                  trailing: Icon(
                    result!.canMockLocation ? Icons.warning : Icons.check_circle,
                    color: result!.canMockLocation ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => result = null);
                      _checkDeviceIntegrity();
                    },
                    child: const Text('Refresh Checks'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      DeviceIntegrityService.resetWarningShown();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Warning status reset')),
                      );
                      SecurityLogger.log('SecurityWarningReset');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Reset Warning Status'),
                  ),
                ),
              ],
            ),
    );
  }
}