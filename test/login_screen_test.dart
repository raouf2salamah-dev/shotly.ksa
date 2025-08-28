import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shotly/src/screens/auth/login_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AuthService], customMocks: [MockSpec<AuthService>(as: #MockTestAuthService)])
import 'login_screen_test.mocks.dart';
import 'package:go_router/go_router.dart';
import 'package:shotly/src/services/auth_service.dart';
import 'test_helpers.dart';
import 'package:shotly/src/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FakeAppLocalizations extends AppLocalizations {
  FakeAppLocalizations(Locale locale) : super(locale);

  final Map<String, String> _fakeStrings = {};

  @override
  Future<bool> load() async {
    _fakeStrings.addAll({
      'login_title': 'Login',
      'email_hint': 'Email',
      'password_hint': 'Password',
      'login_button': 'Login',
      'register_prompt': 'Don\'t have an account? Register',
      'email_error': 'Please enter your email',
      'password_error': 'Please enter your password',
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

void main() {
  group('Login Screen Tests', () {
    late MockTestAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockTestAuthService();
    });

    testWidgets('Login screen renders correctly', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1280);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

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
              GoRoute(path: '/', builder: (_, __) => ChangeNotifierProvider<AuthService>.value(
                value: mockAuthService,
                child: const LoginScreen(),
              )),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.byKey(const Key('loginButton'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('Shows validation errors for empty fields', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1280);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

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
              GoRoute(path: '/', builder: (_, __) => ChangeNotifierProvider<AuthService>.value(
                value: mockAuthService,
                child: const LoginScreen(),
              )),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(const Key('loginButton'), skipOffstage: false);
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Calls sign in method when form is valid', (WidgetTester tester) async {
      when(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => null);
      when(mockAuthService.userRole).thenReturn(UserRole.buyer);

      tester.binding.window.physicalSizeTestValue = const Size(800, 1280);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

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
              GoRoute(path: '/', builder: (_, __) => ChangeNotifierProvider<AuthService>.value(
                value: mockAuthService,
                child: const LoginScreen(),
              )),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      final buttonFinder = find.byKey(const Key('loginButton'), skipOffstage: false);
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pump();

      verify(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });
  });
}