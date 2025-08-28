import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('privacy_policy')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('privacy_policy'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              AppLocalizations.of(context)!.translate('last_updated').replaceAll('{date}', DateTime.now().toString().substring(0, 10)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Introduction
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_introduction_title'),
              content: AppLocalizations.of(context)!.translate('privacy_introduction_content')
            ),
            
            // Information We Collect
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_collect_title'),
              content: AppLocalizations.of(context)!.translate('privacy_collect_content')
            ),
            
            // How We Collect Information
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_how_collect_title'),
              content: AppLocalizations.of(context)!.translate('privacy_how_collect_content')
            ),
            
            // How We Use Your Information
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_use_title'),
              content: AppLocalizations.of(context)!.translate('privacy_use_content')
            ),
            
            // Disclosure of Your Information
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_disclosure_title'),
              content: AppLocalizations.of(context)!.translate('privacy_disclosure_content')
            ),
            
            // Data Security
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_security_title'),
              content: AppLocalizations.of(context)!.translate('privacy_security_content')
            ),
            
            // Your Data Protection Rights
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_rights_title'),
              content: AppLocalizations.of(context)!.translate('privacy_rights_content')
            ),
            
            // Children's Privacy
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_children_title'),
              content: AppLocalizations.of(context)!.translate('privacy_children_content')
            ),
            
            // International Data Transfers
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_transfers_title'),
              content: AppLocalizations.of(context)!.translate('privacy_transfers_content')
            ),
            
            // Changes to This Privacy Policy
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_changes_title'),
              content: AppLocalizations.of(context)!.translate('privacy_changes_content')
            ),
            
            // Contact Us
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('privacy_contact_title'),
              content: AppLocalizations.of(context)!.translate('privacy_contact_content')
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}