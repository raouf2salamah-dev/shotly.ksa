import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations!.translate('analyticsTitle')),
      ),
      body: Center(
        child: Text(appLocalizations.translate('noContent')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Text(appLocalizations.translate('uploadContent')),
      ),
    );
  }
}