import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isFormSubmitted = false;
  
  // Contact information
  final String _supportEmail = "support@digitalcontentmarketplace.com";
  final String _supportPhone = "+966500000000";
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would send the form data to your backend
      // For now, we'll just show a success message
      setState(() {
        _isFormSubmitted = true;
      });
    }
  }
  
  void _resetForm() {
    setState(() {
      _isFormSubmitted = false;
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
    });
  }
  
  void _launchEmail() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Support Request&body=Hello, I need help with...',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  void _launchPhone() async {
    final Uri uri = Uri(
      scheme: 'tel',
      path: _supportPhone,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  void _launchChat() {
    // In a real app, you would launch your chat widget or service
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('liveChatSupportDescription')),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _navigateToFAQ() {
    context.push('/help');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('contactSupportTitle')),
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
              appLocalizations.translate('contactSupportDescription'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            
            // Contact Options
            Text(
              appLocalizations.translate('contactOptions'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Contact Option Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
              children: [
                _buildContactOptionCard(
                  icon: Icons.phone,
                  title: appLocalizations.translate('callUs'),
                  description: appLocalizations.translate('callUsDescription'),
                  onTap: _launchPhone,
                  color: Colors.blue,
                ),
                _buildContactOptionCard(
                  icon: Icons.email,
                  title: appLocalizations.translate('emailSupport'),
                  description: appLocalizations.translate('emailSupportDescription'),
                  onTap: _launchEmail,
                  color: Colors.green,
                ),
                _buildContactOptionCard(
                  icon: Icons.chat,
                  title: appLocalizations.translate('liveChatSupport'),
                  description: appLocalizations.translate('liveChatSupportDescription'),
                  onTap: _launchChat,
                  color: Colors.purple,
                ),
                _buildContactOptionCard(
                  icon: Icons.help,
                  title: appLocalizations.translate('faqSupport'),
                  description: appLocalizations.translate('faqSupportDescription'),
                  onTap: _navigateToFAQ,
                  color: Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            
            // Contact Form
            _isFormSubmitted ? _buildSuccessMessage() : _buildContactForm(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactForm() {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.translate('contactFormTitle'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appLocalizations.translate('contactFormDescription'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                hintText: appLocalizations.translate('yourName'),
                labelText: appLocalizations.translate('yourName'),
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                hintText: appLocalizations.translate('yourEmail'),
                labelText: appLocalizations.translate('yourEmail'),
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _subjectController,
                hintText: appLocalizations.translate('subject'),
                labelText: appLocalizations.translate('subject'),
                prefixIcon: Icons.subject,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _messageController,
                hintText: appLocalizations.translate('message'),
                labelText: appLocalizations.translate('message'),
                prefixIcon: Icons.message,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: appLocalizations.translate('submit'),
                onPressed: _submitForm,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSuccessMessage() {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            appLocalizations.translate('emailSent'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            appLocalizations.translate('emailSentDescription'),
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'OK',
            onPressed: _resetForm,
          ),
        ],
      ),
    );
  }
}