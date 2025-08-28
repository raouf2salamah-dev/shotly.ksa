import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shotly/src/screens/shared/splash_screen.dart';
import 'package:shotly/src/services/auth_service.dart';
import 'package:shotly/src/services/theme_service.dart';
import 'package:shotly/src/services/locale_service.dart';
import 'package:shotly/src/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lottie/lottie.dart';

// Generate mocks
@GenerateNiceMocks([MockSpec<AuthService>(), MockSpec<GoRouter>()])
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';
import 'splash_screen_test.mocks.dart';
import 'package:go_router/go_router.dart';

class MockUser extends Mock implements User {}

class MockGoRouterProvider extends StatelessWidget {
  const MockGoRouterProvider({
    required this.goRouter,
    required this.child,
    super.key,
  });

  final GoRouter goRouter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InheritedGoRouter(
      goRouter: goRouter,
      child: child,
    );
  }
}

void main() {
  group('SplashScreen Tests', () {
    late MockAuthService mockAuthService;
    late ThemeService themeService;
    late LocaleService localeService;
    late MockGoRouter mockGoRouter;

    setUp(() async {
      mockAuthService = MockAuthService();
      themeService = ThemeService();
      localeService = LocaleService();

      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'read') {
          return null;
        }
        return null;
      });

      mockGoRouter = MockGoRouter();
    });

    testWidgets('SplashScreen shows loading animation', (WidgetTester tester) async {
      // Build the splash screen widget
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            locale: const Locale('en'),
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
                ChangeNotifierProvider<ThemeService>.value(value: themeService),
                ChangeNotifierProvider<LocaleService>.value(value: localeService),
              ],
              child: InheritedGoRouter(
                goRouter: mockGoRouter,
                child: const SplashScreen(),
              ),
            ),
          ),
        );

        // Allow widget to build and stabilize
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 50));
        await tester.pump();

        // Verify that the SplashScreen is in the tree
        expect(find.byType(SplashScreen), findsOneWidget);
        // Verify the Center inside SplashScreen
        expect(find.descendant(of: find.byType(SplashScreen), matching: find.byType(Center)), findsOneWidget);
        // Verify the Lottie animation
        expect(find.byType(Lottie), findsOneWidget);
        // Verify the progress indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Verify the text
        expect(find.text('Shotly'), findsOneWidget);
        expect(find.text('Welcome to Shotly'), findsOneWidget);
      });
    });

    testWidgets('SplashScreen navigates to onboarding when user is not logged in', (WidgetTester tester) async {
      // Setup mock behavior
      when(mockAuthService.currentUser).thenAnswer((_) => null);

      await tester.runAsync(() async {
         await tester.pumpWidget(
           MaterialApp(
             localizationsDelegates: [
               AppLocalizations.delegate,
               GlobalMaterialLocalizations.delegate,
               GlobalWidgetsLocalizations.delegate,
               GlobalCupertinoLocalizations.delegate,
             ],
             supportedLocales: const [
               Locale('en'),
               Locale('ar'),
             ],
             locale: const Locale('en'),
             home: MultiProvider(
               providers: [
                 ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
                 ChangeNotifierProvider<ThemeService>.value(value: themeService),
                 ChangeNotifierProvider<LocaleService>.value(value: localeService),
               ],
               child: MockGoRouterProvider(
                 goRouter: mockGoRouter,
                 child: const SplashScreen(),
               ),
             ),
           ),
         );

         // Allow widget to build and stabilize
         await tester.pump();
         await Future.delayed(const Duration(milliseconds: 100));
         await tester.pump();
         await tester.pump(const Duration(milliseconds: 50));
       });

       verify(mockGoRouter.go('/onboarding')).called(1);
       verify(mockAuthService.currentUser).called(1);
    });

    testWidgets('SplashScreen navigates to buyer screen when user is logged in', (WidgetTester tester) async {
      // Setup mock behavior
      final mockUser = MockUser();
      when(mockAuthService.currentUser).thenAnswer((_) => mockUser);

      await tester.runAsync(() async {
         await tester.pumpWidget(
           MaterialApp(
             localizationsDelegates: [
               AppLocalizations.delegate,
               GlobalMaterialLocalizations.delegate,
               GlobalWidgetsLocalizations.delegate,
               GlobalCupertinoLocalizations.delegate,
             ],
             supportedLocales: const [
               Locale('en'),
               Locale('ar'),
             ],
             locale: const Locale('en'),
             home: MultiProvider(
               providers: [
                 ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
                 ChangeNotifierProvider<ThemeService>.value(value: themeService),
                 ChangeNotifierProvider<LocaleService>.value(value: localeService),
               ],
               child: MockGoRouterProvider(
                 goRouter: mockGoRouter,
                 child: const SplashScreen(),
               ),
             ),
           ),
         );

         // Allow widget to build and stabilize
         await tester.pump();
         await Future.delayed(const Duration(milliseconds: 100));
         await tester.pump();
         await tester.pump(const Duration(milliseconds: 50));
       });

       verify(mockGoRouter.go('/buyer')).called(1);
       verify(mockAuthService.currentUser).called(1);
    });
  });
}