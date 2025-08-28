import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:shotly/src/services/auth_service.dart';
import 'package:shotly/src/services/theme_service.dart';
import 'package:shotly/src/services/locale_service.dart';
import 'package:shotly/src/services/search_service.dart';
import 'package:shotly/src/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// A helper class to provide mock services for widget tests
class TestHelpers {
  /// Wraps a widget with necessary providers for testing
  static Widget wrapWithProviders({
    required Widget child,
    AuthService? authService,
    ThemeService? themeService,
    LocaleService? localeService,
    SearchService? searchService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(
          value: authService ?? MockAuthService(),
        ),
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService ?? ThemeService(),
        ),
        ChangeNotifierProvider<LocaleService>.value(
          value: localeService ?? LocaleService(),
        ),
        if (searchService != null)
          ChangeNotifierProvider<SearchService>.value(
            value: searchService,
          ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        locale: const Locale('en'),
        home: child,
      ),
    );
  }
}

/// Mock classes for testing
class MockAuthService extends Mock implements AuthService {}
class MockThemeService extends Mock implements ThemeService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockSearchService extends Mock implements SearchService {}

class FakeThemeService extends ChangeNotifier implements ThemeService {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
  }

  @override
  Future<void> toggleTheme() async {
    await setThemeMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}

class FakeLocaleService extends ChangeNotifier implements LocaleService {
  Locale _locale = Locale('en');

  @override
  Locale get locale => _locale;

  @override
  bool get isArabic => _locale.languageCode == 'ar';

  @override
  bool get isEnglish => _locale.languageCode == 'en';

  @override
  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
  }

  @override
  Future<void> toggleLocale() async {
    await setLocale(_locale.languageCode == 'en' ? Locale('ar') : Locale('en'));
  }
}