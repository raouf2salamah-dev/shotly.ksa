import 'package:flutter/material.dart';
import '../bootstrap/security_bootstrap.dart';

/// SecurityIntro provides a dialog to inform users about the app's security features
/// 
/// This dialog can be shown during first launch or from settings
class SecurityIntro extends StatelessWidget {
  const SecurityIntro({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const SecurityIntroContent(),
    );
  }

  /// Show the security intro dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const SecurityIntro(),
    );
  }
}

class SecurityIntroContent extends StatefulWidget {
  const SecurityIntroContent({Key? key}) : super(key: key);

  @override
  State<SecurityIntroContent> createState() => _SecurityIntroContentState();
}

class _SecurityIntroContentState extends State<SecurityIntroContent> {
  bool _isLoading = true;
  Map<String, dynamic> _securityReport = {};

  @override
  void initState() {
    super.initState();
    _loadSecurityReport();
  }

  Future<void> _loadSecurityReport() async {
    try {
      final report = await SecurityBootstrap.getSecurityReport();
      setState(() {
        _securityReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSecurityFeaturesList(),
          ),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.security,
          size: 48,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        Text(
          'Security Features',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your data is protected by multiple security layers',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSecurityFeaturesList() {
    return ListView(
      shrinkWrap: true,
      children: [
        _buildFeatureItem(
          icon: Icons.lock,
          title: 'Secure Storage',
          description: 'Your sensitive data is encrypted at rest using platform-specific secure storage',
          isActive: true,
        ),
        _buildFeatureItem(
          icon: Icons.verified_user,
          title: 'Request Signing',
          description: 'All API requests are cryptographically signed to prevent tampering',
          isActive: _securityReport['has_signing_key'] ?? false,
        ),
        _buildFeatureItem(
          icon: Icons.security,
          title: 'Certificate Pinning',
          description: 'Prevents man-in-the-middle attacks by validating server certificates',
          isActive: _securityReport['certificate_pinning_enabled'] ?? false,
        ),
        _buildFeatureItem(
          icon: Icons.phonelink_lock,
          title: 'Device Integrity',
          description: 'Detects if your device has been compromised (rooted/jailbroken)',
          isActive: !(_securityReport['device_integrity']?['is_compromised'] ?? true),
        ),
        _buildFeatureItem(
          icon: Icons.token,
          title: 'Token Management',
          description: 'Secure authentication with automatic token refresh',
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isActive ? null : Colors.grey,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (isActive)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive ? null : Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}