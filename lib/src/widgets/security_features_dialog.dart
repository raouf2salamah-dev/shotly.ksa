import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/secure_storage_service.dart';

/// A dialog that explains the new security features to users
/// This should be shown when users first encounter the security features
class SecurityFeaturesDialog extends StatelessWidget {
  /// Whether to show the dialog only once
  final bool showOnce;

  /// Preference key to track if the dialog has been shown
  static const String _prefKey = 'security_features_dialog_shown';

  const SecurityFeaturesDialog({super.key, this.showOnce = true});

  /// Shows the security features dialog if it hasn't been shown before
  /// Returns true if the dialog was shown, false otherwise
  static Future<bool> showIfNeeded(BuildContext context) async {
    if (context.mounted) {
      // Check if we've shown this dialog before
      if (await _shouldShow()) {
        await showDialog(
          context: context,
          builder: (context) => const SecurityFeaturesDialog(),
        );
        
        // Mark as shown if showOnce is true
        await SecureStorageService.write(_prefKey, 'true');
        return true;
      }
    }
    return false;
  }

  /// Determines if the dialog should be shown
  static Future<bool> _shouldShow() async {
    final value = await SecureStorageService.read(_prefKey);
    return value != 'true';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('New Security Features'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureItem(
              context,
              icon: Icons.screenshot_monitor,
              title: 'Screenshot Protection',
              description: 'Screenshots and app switcher previews of protected content are now disabled.',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              icon: Icons.fingerprint,
              title: 'Biometric Authentication',
              description: 'Biometric authentication may be required after a timeout period.',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              icon: Icons.settings,
              title: 'Customizable Settings',
              description: 'You can adjust timeout duration and authentication requirements in Settings.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/security-examples');
          },
          child: const Text('Learn More'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}