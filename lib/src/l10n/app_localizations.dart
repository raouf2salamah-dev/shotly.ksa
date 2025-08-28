import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      // Enhanced debugging for asset loading issues
      print('DEBUG: ===== TRANSLATION LOADING START =====');
      print('DEBUG: Current locale: ${locale.languageCode}');
      print('DEBUG: Platform: ${identical(0, 0.0) ? "Web" : "Native"}');
      
      // List of paths to try in order
      final List<String> pathsToTry = [
        'assets/lang/${locale.languageCode}.json',
        'lang/${locale.languageCode}.json',
        'assets/assets/lang/${locale.languageCode}.json',
        '/${locale.languageCode}.json',
        '/assets/lang/${locale.languageCode}.json',
      ];
      
      print('DEBUG: Will try these paths in order: $pathsToTry');
      
      // Try each path until one works
      for (final String assetPath in pathsToTry) {
        print('DEBUG: Attempting to load from: $assetPath');
        try {
          // Try to load the file
          final String jsonString = await rootBundle.loadString(assetPath);
          print('DEBUG: SUCCESS! Loaded file from: $assetPath');
          print('DEBUG: File content length: ${jsonString.length} characters');
          print('DEBUG: First 100 chars: ${jsonString.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}...');
          
          // Try to parse the JSON
          try {
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            print('DEBUG: Successfully parsed JSON with ${jsonMap.length} keys');
            
            // Convert to string map
            _localizedStrings = jsonMap.map((key, value) {
              return MapEntry(key, value.toString());
            });
            
            print('DEBUG: Loaded ${_localizedStrings.length} translations for ${locale.languageCode}');
            
            // Print sample keys to verify content
            if (_localizedStrings.isNotEmpty) {
              final List<String> sampleKeys = _localizedStrings.keys.take(5).toList();
              print('DEBUG: Sample keys: $sampleKeys');
              for (var key in sampleKeys) {
                print('DEBUG: $key = ${_localizedStrings[key]}');
              }
            } else {
              print('DEBUG: WARNING - _localizedStrings is empty after successful load!');
            }
            
            print('DEBUG: ===== TRANSLATION LOADING SUCCESS =====');
            return true;
          } catch (jsonError) {
            print('DEBUG: JSON parsing error: $jsonError');
            print('DEBUG: Invalid JSON content in file: $assetPath');
            // Continue to next path
          }
        } catch (loadError) {
          print('DEBUG: Failed to load from $assetPath: $loadError');
          // Continue to next path
        }
      }
      
      // If we get here, all paths failed
      print('DEBUG: All paths failed to load translations');
      print('DEBUG: ===== TRANSLATION LOADING FAILED =====');
      _localizedStrings = {};
      return false;
    } catch (e) {
      print('ERROR: Unexpected error in load method: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      // Fallback to empty strings if loading fails
      _localizedStrings = {};
      return false;
    }
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

// LocalizationsDelegate is a factory for a set of localized resources
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}