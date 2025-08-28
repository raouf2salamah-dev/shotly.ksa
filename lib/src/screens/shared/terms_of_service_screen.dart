import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('terms_of_service')),
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
              AppLocalizations.of(context)!.translate('terms_of_service'),
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
              title: AppLocalizations.of(context)!.translate('terms_introduction_title'),
              content: AppLocalizations.of(context)!.translate('terms_introduction_content')
            ),
            
            // Definitions
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_definitions_title'),
              content: AppLocalizations.of(context)!.translate('terms_definitions_content')
            ),
            
            // Account Registration
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_account_title'),
              content: AppLocalizations.of(context)!.translate('terms_account_content')
            ),
            
            // User Conduct
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_conduct_title'),
              content: AppLocalizations.of(context)!.translate('terms_conduct_content')
            ),
            
            // Content Policies
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_content_title'),
              content: AppLocalizations.of(context)!.translate('terms_content_policies')
            ),
            
            // Purchases and Payments
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_purchases_title'),
              content: AppLocalizations.of(context)!.translate('terms_purchases_content')
            ),
            
            // Refunds and Returns
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_refunds_title'),
              content: AppLocalizations.of(context)!.translate('terms_refunds_content')
            ),
            
            // Intellectual Property
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_intellectual_property_title'),
              content: AppLocalizations.of(context)!.translate('terms_intellectual_property_content')
            ),
            
            // Limitation of Liability
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_liability_title'),
              content: AppLocalizations.of(context)!.translate('terms_liability_content')
            ),
            
            // Termination
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_termination_title'),
              content: AppLocalizations.of(context)!.translate('terms_termination_content')
            ),
            
            // Changes to Terms
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_changes_title'),
              content: AppLocalizations.of(context)!.translate('terms_changes_content')
            ),
            
            // Contact Information
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.translate('terms_contact_title'),
              content: AppLocalizations.of(context)!.translate('terms_contact_content')
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