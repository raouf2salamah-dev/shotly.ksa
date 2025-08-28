import 'package:flutter/material.dart';

/// A dialog that introduces the security features of the application to users
/// 
/// This dialog is typically shown once when the user first launches the app
class SecurityIntroDialog extends StatelessWidget {
  /// Creates a security introduction dialog
  /// 
  /// The [title], [features], and [buttonText] can be customized
  const SecurityIntroDialog({
    Key? key,
    this.title = 'Security Features',
    this.features = const [
      SecurityFeature(
        icon: Icons.lock,
        title: 'Secure Storage',
        description: 'Sensitive data is stored in encrypted storage',
      ),
      SecurityFeature(
        icon: Icons.verified_user,
        title: 'Request Signing',
        description: 'API requests are signed to prevent tampering',
      ),
      SecurityFeature(
        icon: Icons.phonelink_lock,
        title: 'Device Integrity',
        description: 'Checks for compromised devices',
      ),
      SecurityFeature(
        icon: Icons.timer,
        title: 'Token Management',
        description: 'Secure handling of authentication tokens',
      ),
    ],
    this.buttonText = 'I Understand',
  }) : super(key: key);

  /// The title of the dialog
  final String title;
  
  /// The list of security features to display
  final List<SecurityFeature> features;
  
  /// The text for the confirmation button
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.security, color: Colors.blue),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This app includes several security features to protect your data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => _SecurityFeatureItem(feature: feature)),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(buttonText),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

/// Represents a security feature to be displayed in the SecurityIntroDialog
class SecurityFeature {
  /// Creates a security feature
  /// 
  /// The [icon], [title], and [description] are required
  const SecurityFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  /// The icon representing the feature
  final IconData icon;
  
  /// The title of the feature
  final String title;
  
  /// A brief description of the feature
  final String description;
}

class _SecurityFeatureItem extends StatelessWidget {
  final SecurityFeature feature;

  const _SecurityFeatureItem({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  feature.description,
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