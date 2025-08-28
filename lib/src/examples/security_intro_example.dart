import 'package:flutter/material.dart';
import '../security/security_dialog_manager.dart';
import '../security/security_intro_dialog.dart';

/// A simple example showing how to use SecurityDialogManager with SecurityIntroDialog
class SecurityIntroExample extends StatelessWidget {
  const SecurityIntroExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Introduction'),
      ),
      body: FutureBuilder<bool>(
        // Check if the dialog has been shown before
        future: SecurityDialogManager.hasSecurityDialogBeenShown(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final hasBeenShown = snapshot.data!;
          
          // Show the dialog if it hasn't been shown before
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSecurityDialogIfNeeded(context);
          });
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasBeenShown ? Icons.check_circle : Icons.info,
                  color: hasBeenShown ? Colors.green : Colors.blue,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  hasBeenShown
                      ? 'Security introduction has been shown before'
                      : 'Security introduction will be shown now',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _showSecurityDialog(context),
                  child: const Text('Show Security Dialog Again'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _resetDialogStatus(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                  ),
                  child: const Text('Reset Dialog Status'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSecurityDialogIfNeeded(BuildContext context) async {
    // Use the SecurityDialogManager to show the dialog if needed
    await SecurityDialogManager.showSecurityIntroDialogIfNeeded(
      context: context,
      dialogBuilder: () => const SecurityIntroDialog(
        // You can customize the dialog here
        title: 'App Security Features',
        buttonText: 'Got It',
      ),
    );
  }
  
  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SecurityIntroDialog(),
    );
  }
  
  Future<void> _resetDialogStatus(BuildContext context) async {
    await SecurityDialogManager.resetSecurityDialogShownStatus();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dialog status reset. Restart the app to see the dialog again.')),
      );
    }
  }
}