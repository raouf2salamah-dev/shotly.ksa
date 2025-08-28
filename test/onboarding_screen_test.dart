import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shotly/src/screens/auth/onboarding_screen.dart';
import 'package:shotly/src/services/auth_service.dart';
import 'package:shotly/src/services/theme_service.dart';
import 'package:shotly/src/services/locale_service.dart';
import 'test_helpers.dart';
import 'package:shotly/src/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class FakeAppLocalizations extends AppLocalizations {
  FakeAppLocalizations(Locale locale) : super(locale);

  final Map<String, String> _fakeStrings = {};

  @override
  Future<bool> load() async {
    _fakeStrings.addAll({
      'onboarding_title_1': 'Title 1',
      'onboarding_desc_1': 'Desc 1',
      'onboarding_title_2': 'Title 2',
      'onboarding_desc_2': 'Desc 2',
      'onboarding_title_3': 'Title 3',
      'onboarding_desc_3': 'Desc 3',
      'onboarding_title_4': 'Title 4',
      'onboarding_desc_4': 'Desc 4',
      'onboarding_skip': 'Skip',
      'onboarding_next': 'Next',
      'onboarding_get_started': 'Get Started',
    });
    return true;
  }

  @override
  String translate(String key) {
    return _fakeStrings[key] ?? key;
  }
}

class FakeLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = FakeAppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool isSupported(Locale locale) => true;

  @override
  bool shouldReload(_) => false;
}

// Mock GoRouter for navigation testing
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('Onboarding Screen Tests', () {
    late MockAuthService mockAuthService;
    late FakeThemeService fakeThemeService;
    late FakeLocaleService fakeLocaleService;

    setUp(() {
      mockAuthService = MockAuthService();
      fakeThemeService = FakeThemeService();
      fakeLocaleService = FakeLocaleService();
      
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });
    
    testWidgets('Onboarding screen shows page indicators', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp.router(
            locale: Locale('en'),
            localizationsDelegates: [
              FakeLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('ar')],
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: mockAuthService),
                      ChangeNotifierProvider.value(value: fakeThemeService),
                      ChangeNotifierProvider.value(value: fakeLocaleService),
                    ],
                    child: const OnboardingScreen(),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Row), findsWidgets);
        expect(find.byType(PageView), findsOneWidget);
      });
    });
    
    testWidgets('Onboarding screen has navigation buttons', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp.router(
            locale: Locale('en'),
            localizationsDelegates: [
              FakeLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('ar')],
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: mockAuthService),
                      ChangeNotifierProvider.value(value: fakeThemeService),
                      ChangeNotifierProvider.value(value: fakeLocaleService),
                    ],
                    child: const OnboardingScreen(),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(TextButton), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      });
    });

    testWidgets('Onboarding screen renders correctly', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp.router(
            locale: Locale('en'),
            localizationsDelegates: [
              FakeLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('ar')],
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: mockAuthService),
                      ChangeNotifierProvider.value(value: fakeThemeService),
                      ChangeNotifierProvider.value(value: fakeLocaleService),
                    ],
                    child: const OnboardingScreen(),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(PageView), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });


  });
}