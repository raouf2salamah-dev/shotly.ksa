import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;
  final bool useIconButton;
  final Color? iconColor;
  final double iconSize;

  const LanguageSwitcher({
    super.key,
    this.showLabel = true,
    this.useIconButton = false,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final theme = Theme.of(context);
    
    return useIconButton
        ? IconButton(
            icon: Icon(
              Icons.language,
              color: iconColor,
              size: iconSize,
            ),
            tooltip: AppLocalizations.of(context)?.translate('language') ?? 'Language',
            onPressed: () => _showLanguageDialog(context, localeService),
          )
        : InkWell(
            onTap: () => _showLanguageDialog(context, localeService),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    color: iconColor ?? theme.iconTheme.color,
                    size: iconSize,
                  ),
                  if (showLabel) ...[  
                    const SizedBox(width: 8),
                    Text(
                      localeService.locale.languageCode == 'en' ? 'EN' : 'AR',
                      style: TextStyle(
                        color: iconColor ?? theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
  }

  void _showLanguageDialog(BuildContext context, LocaleService localeService) {
    final theme = Theme.of(context);
    final isRtl = localeService.locale.languageCode == 'ar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.translate('language') ?? 'Language',
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildLanguageOption(
              context,
              'English',
              const Locale('en'),
              localeService,
              theme,
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              context,
              'العربية',
              const Locale('ar'),
              localeService,
              theme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    Locale locale,
    LocaleService localeService,
    ThemeData theme,
  ) {
    final isSelected = localeService.locale.languageCode == locale.languageCode;
    
    return InkWell(
      onTap: () {
        localeService.setLocale(locale);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}