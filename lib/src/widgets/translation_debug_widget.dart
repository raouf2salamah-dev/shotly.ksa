import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import 'package:provider/provider.dart';

/// A widget specifically designed to debug translation issues
/// This widget directly loads and displays translations with detailed logging
class TranslationDebugWidget extends StatefulWidget {
  const TranslationDebugWidget({super.key});

  @override
  State<TranslationDebugWidget> createState() => _TranslationDebugWidgetState();
}

class _TranslationDebugWidgetState extends State<TranslationDebugWidget> {
  Map<String, String> _translations = {};
  String _loadingStatus = 'Not started';
  String _currentLocale = 'Unknown';
  
  @override
  void initState() {
    super.initState();
    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTranslations();
    });
  }
  
  Future<void> _loadTranslations() async {
    try {
      setState(() {
        _loadingStatus = 'Loading...';
      });
      
      final localeService = Provider.of<LocaleService>(context, listen: false);
      final locale = localeService.locale;
      
      setState(() {
        _currentLocale = locale.toString();
      });
      
      // Create a new instance to test direct loading
      final appLocalizations = AppLocalizations(locale);
      final success = await appLocalizations.load();
      
      if (success) {
        // Get a sample of translations to display
        final sampleTranslations = <String, String>{};
        final keys = [
          'greeting',
          'language',
          'settings',
          'darkMode',
          'discover'
        ];
        
        for (final key in keys) {
          sampleTranslations[key] = appLocalizations.translate(key);
        }
        
        setState(() {
          _translations = sampleTranslations;
          _loadingStatus = 'Loaded successfully';
        });
      } else {
        setState(() {
          _loadingStatus = 'Failed to load translations';
        });
      }
    } catch (e) {
      setState(() {
        _loadingStatus = 'Error: $e';
      });
    }
  }
  
  void _toggleLocale() {
    final localeService = Provider.of<LocaleService>(context, listen: false);
    localeService.toggleLocale();
    
    // Clear and reload with new locale
    setState(() {
      _translations = {};
      _loadingStatus = 'Toggled locale, reloading...';
    });
    
    // Delay to ensure locale change is processed
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadTranslations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTranslations,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Locale: $_currentLocale',
                style: Theme.of(context).textTheme.titleLarge),
            Text('Loading Status: $_loadingStatus',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            const Text('Translation Samples:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: _translations.isEmpty
                  ? const Center(child: Text('No translations loaded'))
                  : ListView.builder(
                      itemCount: _translations.length,
                      itemBuilder: (context, index) {
                        final key = _translations.keys.elementAt(index);
                        final value = _translations[key];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(key),
                            subtitle: Text(value ?? 'null'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleLocale,
        label: const Text('Toggle Language'),
        icon: const Icon(Icons.language),
      ),
    );
  }
}