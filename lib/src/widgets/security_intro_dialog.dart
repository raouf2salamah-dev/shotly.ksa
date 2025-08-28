import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A dialog that introduces users to the security features of the app
/// This is shown the first time a user encounters security features
class SecurityIntroDialog extends StatelessWidget {
  const SecurityIntroDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Security Features'),
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
              description: 'Screenshots and app switcher previews of protected content are disabled.',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              icon: Icons.visibility_off,
              title: 'Background Protection',
              description: 'Sensitive content is hidden when the app goes to the background.',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              icon: Icons.fingerprint,
              title: 'Biometric Authentication',
              description: 'Biometric authentication may be required after a timeout period.',
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