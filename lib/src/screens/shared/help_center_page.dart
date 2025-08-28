import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({Key? key}) : super(key: key);

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  // Get localized category names
  Map<String, List<Map<String, String>>> _getLocalizedFaqCategories(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    
    return {
      appLocalizations?.translate("accountAndProfile") ?? "Account & Profile": [
      {
        "question": appLocalizations?.translate("faq_create_account") ?? "How do I create an account?",
        "answer": appLocalizations?.translate("faq_create_account_answer") ?? "You can create an account by tapping the 'Sign Up' button on the login screen and following the registration steps."
      },
      {
        "question": appLocalizations?.translate("faq_update_profile") ?? "How do I update my profile information?",
        "answer": appLocalizations?.translate("faq_update_profile_answer") ?? "Go to your profile page, tap on 'Edit Profile', make your changes, and save them."
      },
      {
        "question": appLocalizations?.translate("faq_reset_password") ?? "How can I reset my password?",
        "answer": appLocalizations?.translate("faq_reset_password_answer") ?? "Go to Settings > Account > Reset Password, and follow the instructions."
      },
      {
        "question": appLocalizations?.translate("faq_delete_account") ?? "How do I delete my account?",
        "answer": appLocalizations?.translate("faq_delete_account_answer") ?? "Go to Settings > Account > Delete Account. Please note this action cannot be undone."
      },
    ],
    appLocalizations?.translate("ordersAndPayments") ?? "Orders & Payments": [
      {
        "question": appLocalizations?.translate("faq_place_order") ?? "How do I place an order?",
        "answer": appLocalizations?.translate("faq_place_order_answer") ?? "Browse products, select the item you want, add it to your cart, and proceed to checkout."
      },
      {
        "question": appLocalizations?.translate("faq_payment_methods") ?? "What payment methods are supported?",
        "answer": appLocalizations?.translate("faq_payment_methods_answer") ?? "We support credit/debit cards, PayPal, and other local payment options depending on your region."
      },
      {
        "question": appLocalizations?.translate("faq_track_order") ?? "How do I track my order?",
        "answer": appLocalizations?.translate("faq_track_order_answer") ?? "Go to 'My Orders' in your profile and select the order you want to track."
      },
      {
        "question": appLocalizations?.translate("faq_refund") ?? "Can I get a refund or cancel my order?",
        "answer": appLocalizations?.translate("faq_refund_answer") ?? "You can request cancellation within 24 hours of placing an order. Refund policies vary by product type."
      },
    ],
    appLocalizations?.translate("usingTheApp") ?? "Using the App": [
      {
        "question": appLocalizations?.translate("faq_search") ?? "How do I search for a product/service?",
        "answer": appLocalizations?.translate("faq_search_answer") ?? "Use the search bar at the top of the home screen and enter keywords related to what you're looking for."
      },
      {
        "question": appLocalizations?.translate("faq_favorites") ?? "How do I add items to my favorites?",
        "answer": appLocalizations?.translate("faq_favorites_answer") ?? "Tap the heart icon on any product to add it to your favorites list."
      },
    ],
    appLocalizations?.translate("technicalIssues") ?? "Technical Issues": [
      {
        "question": appLocalizations?.translate("faq_app_not_loading") ?? "The app is not loading — what should I do?",
        "answer": appLocalizations?.translate("faq_app_not_loading_answer") ?? "Try closing and reopening the app, check your internet connection, or reinstall the app if the issue persists."
      },
      {
        "question": appLocalizations?.translate("faq_cant_login") ?? "I can't log in — how do I fix it?",
        "answer": appLocalizations?.translate("faq_cant_login_answer") ?? "Ensure you're using the correct credentials, reset your password if needed, or contact support if issues continue."
      },
      {
        "question": appLocalizations?.translate("faq_report_bug") ?? "How do I report a bug or problem?",
        "answer": appLocalizations?.translate("faq_report_bug_answer") ?? "Use the 'Contact Support' section to email or WhatsApp us with details about the issue you're experiencing."
      },
    ],
    appLocalizations?.translate("securityAndPrivacy") ?? "Security & Privacy": [
      {
        "question": appLocalizations?.translate("faq_data_protection") ?? "How is my data protected?",
        "answer": appLocalizations?.translate("faq_data_protection_answer") ?? "We use industry-standard encryption and security measures to protect your personal information and transaction data."
      },
      {
        "question": appLocalizations?.translate("faq_personal_info") ?? "Who can see my personal information?",
        "answer": appLocalizations?.translate("faq_personal_info_answer") ?? "Your personal information is only visible to you and authorized staff. We never share your data with third parties without consent."
      },
      {
        "question": appLocalizations?.translate("faq_block_user") ?? "How do I block or report another user?",
        "answer": appLocalizations?.translate("faq_block_user_answer") ?? "Go to the user's profile, tap the three dots menu, and select 'Block User' or 'Report User'."
      },
    ],
    };
  }
  
  // Flattened list for search functionality
  List<Map<String, String>> _getFaqs(BuildContext context) {
    List<Map<String, String>> allFaqs = [];
    final categories = _getLocalizedFaqCategories(context);
    categories.forEach((category, faqList) {
      allFaqs.addAll(faqList);
    });
    return allFaqs;
  }

  String _searchQuery = "";

  // Contact Support Links
  final String _supportEmail = "shotly.ksa@gmail.com";
  final String _whatsAppNumber = "+966500000000";
  final String _supportPhone = "+966500000000";

  void _launchEmail() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=App Support&body=Hello, I need help with...',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWhatsApp() async {
    final Uri uri = Uri.parse("https://wa.me/${_whatsAppNumber.replaceAll('+', '')}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchPhone() async {
    final Uri uri = Uri(scheme: 'tel', path: _supportPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    final allFaqs = _getFaqs(context);
    final categories = _getLocalizedFaqCategories(context);
    
    final filteredFaqs = allFaqs
        .where((faq) =>
            faq["question"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq["answer"]!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations?.translate("helpCenter") ?? "Help Center"),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              labelText: appLocalizations?.translate("searchFAQs") ?? "Search FAQs",
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // FAQs Section
          Text(
            appLocalizations?.translate("frequentlyAskedQuestions") ?? "Frequently Asked Questions",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),

          // If searching, show filtered results
          if (_searchQuery.isNotEmpty) ...
            filteredFaqs.map((faq) {
              return ExpansionTile(
                title: Text(faq["question"]!),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(faq["answer"]!),
                  )
                ],
              );
            }),

          // If not searching, show categorized FAQs
          if (_searchQuery.isEmpty) ...
            categories.entries.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      category.key,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...category.value.map((faq) {
                    return ExpansionTile(
                      title: Text(faq["question"]!),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(faq["answer"]!),
                        )
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),

          const Divider(height: 40),

          // Contact Support
          Text(
            appLocalizations?.translate("contactSupport") ?? "Contact Support",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: Text(appLocalizations?.translate("emailUs") ?? "Email Us"),
            onTap: _launchEmail,
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
            title: Text(appLocalizations?.translate("whatsApp") ?? "WhatsApp"),
            onTap: _launchWhatsApp,
          ),
        ],
      ),
      ),
    );
  }
}