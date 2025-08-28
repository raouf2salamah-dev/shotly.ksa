import 'package:flutter/material.dart';
import '../security/security_dialog_manager.dart';

/// Example showing how to use SecurityDialogManager to display a security introduction dialog
class SecurityDialogExample extends StatefulWidget {
  const SecurityDialogExample({Key? key}) : super(key: key);

  @override
  State<SecurityDialogExample> createState() => _SecurityDialogExampleState();
}

class _SecurityDialogExampleState extends State<SecurityDialogExample> {
  bool _dialogWasShown = false;
  bool _dialogHasBeenShownBefore = false;
  
  @override
  void initState() {
    super.initState();
    _checkDialogStatus();
    _showSecurityIntroDialog();
  }
  
  Future<void> _checkDialogStatus() async {
    final hasBeenShown = await SecurityDialogManager.hasSecurityDialogBeenShown();
    if (mounted) {
      setState(() {
        _dialogHasBeenShownBefore = hasBeenShown;
      });
    }
  }

  Future<void> _showSecurityIntroDialog() async {
    final wasShown = await SecurityDialogManager.showSecurityIntroDialogIfNeeded(
      context: context,
      dialogBuilder: () => _buildSecurityIntroDialog(),
    );
    
    if (mounted) {
      setState(() {
        _dialogWasShown = wasShown;
      });
    }
  }
  
  Future<void> _resetDialogStatus() async {
    await SecurityDialogManager.resetSecurityDialogShownStatus();
    await _checkDialogStatus();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dialog status reset. Restart the app to see the dialog again.')),
    );
  }
  
  Widget _buildSecurityIntroDialog() {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.security, color: Colors.blue),
          const SizedBox(width: 10),
          const Text('Security Features'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app includes several security features to protect your data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _SecurityFeatureItem(
              icon: Icons.lock,
              title: 'Secure Storage',
              description: 'Sensitive data is stored in encrypted storage',
            ),
            _SecurityFeatureItem(
              icon: Icons.verified_user,
              title: 'Request Signing',
              description: 'API requests are signed to prevent tampering',
            ),
            _SecurityFeatureItem(
              icon: Icons.phonelink_lock,
              title: 'Device Integrity',
              description: 'Checks for compromised devices',
            ),
            _SecurityFeatureItem(
              icon: Icons.timer,
              title: 'Token Management',
              description: 'Secure handling of authentication tokens',
            ),
          ],
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dialog Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Dialog Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow(
                      'Dialog shown on this launch:',
                      _dialogWasShown,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Dialog has been shown before:',
                      _dialogHasBeenShownBefore,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _buildSecurityIntroDialog(),
                );
              },
              child: const Text('Show Security Dialog Again'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetDialogStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
              child: const Text('Reset Dialog Status'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, bool value) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: value ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value ? 'Yes' : 'No',
            style: TextStyle(
              color: value ? Colors.green.shade800 : Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityFeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SecurityFeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}