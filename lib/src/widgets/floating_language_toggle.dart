import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';

class FloatingLanguageToggle extends StatelessWidget {
  const FloatingLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final theme = Theme.of(context);
    final isEnglish = localeService.locale.languageCode == 'en';
    
    return Positioned(
       bottom: 100,
       right: 20,
       child: Column(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.end,
         crossAxisAlignment: CrossAxisAlignment.end,
         children: [
           // Debug button
           Padding(
             padding: const EdgeInsets.only(bottom: 8.0),
             child: FloatingActionButton.small(
               heroTag: 'debugTranslations',
               onPressed: () {
                 context.go('/debug/translations');
               },
               backgroundColor: Colors.orange,
               child: const Icon(Icons.bug_report),
             ),
           ),
           // Language toggle button
           FloatingActionButton.extended(
             backgroundColor: theme.colorScheme.primaryContainer,
             foregroundColor: theme.colorScheme.onPrimaryContainer,
             onPressed: () {
               // Toggle between English and Arabic
               final newLocale = isEnglish ? const Locale('ar') : const Locale('en');
               localeService.setLocale(newLocale);
               
               // Show a snackbar to confirm the language change
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text(
                     isEnglish 
                       ? 'تم تغيير اللغة إلى العربية' 
                       : 'Language changed to English',
                     style: const TextStyle(fontSize: 16),
                   ),
                   duration: const Duration(seconds: 2),
                   behavior: SnackBarBehavior.floating,
                 ),
               );
             },
             icon: const Icon(Icons.language),
             label: Text(
               isEnglish ? 'العربية' : 'English',
               style: const TextStyle(fontWeight: FontWeight.bold),
             ),
           ),
         ],
       ),
     );
  }
}