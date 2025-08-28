import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecurityExamplesMenu extends StatelessWidget {
  const SecurityExamplesMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildExampleButton(
              context,
              title: 'Screenshot Protection Demo',
              description: 'Demonstrates cross-platform screenshot detection and prevention techniques',
              route: '/screenshot-protection-demo',
              icon: Icons.security,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Sensitive Data Protection',
              description: 'Demonstrates automatic clearing of sensitive data when app enters background',
              route: '/sensitive-data-demo',
              icon: Icons.data_usage,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Inactivity Timeout',
              description: 'Demonstrates automatic locking after app has been in background for 5 minutes',
              route: '/inactivity-timeout-demo',
              icon: Icons.lock_clock,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Auth Interceptor Example',
              description: 'Demonstrates secure token management with automatic refresh for API requests',
              route: '/auth-interceptor-example',
              icon: Icons.token,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Signed API Example',
              description: 'Demonstrates HMAC-SHA256 request signing with secure device key storage',
              route: '/signed-api-example',
              icon: Icons.verified_user,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Security Dialog Example',
              description: 'Demonstrates one-time security introduction dialog with persistence',
              route: '/security-dialog-example',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Security Intro Example',
              description: 'Shows how to use the SecurityIntroDialog with persistence',
              route: '/security-intro-example',
              icon: Icons.security,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'App Initialization Example',
              description: 'Demonstrates integrating security dialogs into app startup flow',
              route: '/app-initialization-example',
              icon: Icons.app_registration,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Sensitive Screen Dialog Example',
              description: 'Shows security dialogs when entering sensitive screens for the first time in a session',
              route: '/sensitive-screen-dialog-example',
              icon: Icons.screen_lock_portrait,
            ),
            // More security examples can be added here in the future
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Implementation Examples',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'These examples demonstrate best practices for implementing security features in Flutter applications:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Screenshot detection and prevention'),
            _buildBulletPoint('Platform-specific security implementations'),
            _buildBulletPoint('Secure content protection techniques'),
            _buildBulletPoint('Automatic locking after inactivity'),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildExampleButton(BuildContext context, {
    required String title,
    required String description,
    required String route,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}