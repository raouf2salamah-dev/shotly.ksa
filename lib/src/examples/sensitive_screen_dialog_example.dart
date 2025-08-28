import 'package:flutter/material.dart';
import '../security/security_dialog_manager.dart';

/// Example demonstrating how to show security dialogs when entering sensitive screens
class SensitiveScreenDialogExample extends StatefulWidget {
  const SensitiveScreenDialogExample({super.key});

  @override
  State<SensitiveScreenDialogExample> createState() => _SensitiveScreenDialogExampleState();
}

class _SensitiveScreenDialogExampleState extends State<SensitiveScreenDialogExample> {
  bool _hasShownPaymentDialog = false;
  bool _hasShownProfileDialog = false;
  bool _hasShownSettingsDialog = false;

  @override
  void initState() {
    super.initState();
    // Preload dialog statuses for better performance
    SecurityDialogManager.preloadDialogStatus([
      'payment_screen',
      'profile_screen',
      'settings_screen',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensitive Screen Dialogs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This example demonstrates showing security dialogs when entering sensitive screens for the first time in a session.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildSensitiveScreenButtons(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                SecurityDialogManager.resetSessionDialogs();
                setState(() {
                  _hasShownPaymentDialog = false;
                  _hasShownProfileDialog = false;
                  _hasShownSettingsDialog = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session dialogs reset')),
                );
              },
              child: const Text('Reset Session (Simulate App Restart)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dialog Status This Session:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStatusRow('Payment Screen Dialog', _hasShownPaymentDialog),
            _buildStatusRow('Profile Screen Dialog', _hasShownProfileDialog),
            _buildStatusRow('Settings Screen Dialog', _hasShownSettingsDialog),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String name, bool shown) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(name, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: shown ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shown ? 'Shown' : 'Not Shown',
              style: TextStyle(
                color: shown ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitiveScreenButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sensitive Screens:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _showSensitiveScreen('payment_screen', 'Payment Information', Icons.payment),
          child: const Text('Enter Payment Screen'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _showSensitiveScreen('profile_screen', 'Personal Information', Icons.person),
          child: const Text('Enter Profile Screen'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _showSensitiveScreen('settings_screen', 'Security Settings', Icons.settings),
          child: const Text('Enter Settings Screen'),
        ),
      ],
    );
  }

  Future<void> _showSensitiveScreen(String screenKey, String title, IconData icon) async {
    // Show the security dialog for this sensitive screen if not shown yet in this session
    bool dialogShown = await SecurityDialogManager.showSensitiveScreenDialogInSession(
      context,
      screenKey,
      () => _buildSecurityDialog(title, icon),
    );

    // Update the UI to reflect which dialogs have been shown
    setState(() {
      if (screenKey == 'payment_screen') {
        _hasShownPaymentDialog = true;
      } else if (screenKey == 'profile_screen') {
        _hasShownProfileDialog = true;
      } else if (screenKey == 'settings_screen') {
        _hasShownSettingsDialog = true;
      }
    });

    // Navigate to the sensitive screen (simulated with a snackbar)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dialogShown 
                ? 'First visit to $title screen this session - dialog shown' 
                : 'Returning to $title screen - no dialog needed',
          ),
        ),
      );
    }
  }

  Widget _buildSecurityDialog(String title, IconData icon) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text('Accessing $title'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You are about to access $title.'),
          const SizedBox(height: 8),
          const Text(
            'This area contains sensitive information. Please ensure:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• You are in a private location'),
          const Text('• No one is looking over your shoulder'),
          const Text('• You will lock your device when finished'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('I Understand'),
        ),
      ],
    );
  }
}