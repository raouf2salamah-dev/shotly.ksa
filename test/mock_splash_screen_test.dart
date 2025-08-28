import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shotly/src/services/auth_service.dart';
import 'package:shotly/src/services/theme_service.dart';
import 'package:shotly/src/services/locale_service.dart';
import 'mocks/mock_splash_screen.dart';

// Generate mocks
@GenerateMocks([AuthService])
import 'mock_splash_screen_test.mocks.dart';

void main() {
  group('Mock SplashScreen Tests', () {
    late MockAuthService mockAuthService;
    late ThemeService themeService;
    late LocaleService localeService;

    setUp(() {
      mockAuthService = MockAuthService();
      themeService = ThemeService();
      localeService = LocaleService();
    });

    testWidgets('MockSplashScreen renders correctly', (WidgetTester tester) async {
      // Build the mock splash screen widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
              ChangeNotifierProvider<ThemeService>.value(value: themeService),
              ChangeNotifierProvider<LocaleService>.value(value: localeService),
            ],
            child: const MockSplashScreen(key: Key('splash'), skipInitialAuthCheck: true),
          ),
        ),
      );

      // Verify basic structure without waiting for timers
      expect(find.byType(MockSplashScreen), findsOneWidget);
      expect(find.byType(Center), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verify text elements
      expect(find.text('Shotly'), findsOneWidget);
      expect(find.text('Welcome to Shotly'), findsOneWidget);
    });

    testWidgets('MockSplashScreen checks auth status for non-logged in user', 
        (WidgetTester tester) async {
      // Setup mock behavior
      when(mockAuthService.isLoggedIn).thenReturn(false);

      // Create a widget reference we can access later
      late MockSplashScreenState splashScreenState;
      
      // Build the mock splash screen widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
              ChangeNotifierProvider<ThemeService>.value(value: themeService),
              ChangeNotifierProvider<LocaleService>.value(value: localeService),
            ],
            child: MockSplashScreen(
          key: const Key('splash'),
          skipInitialAuthCheck: true,
          onCreated: (state) {
            splashScreenState = state;
          },
        ),
          ),
        ),
      );

      // Manually trigger auth check
      splashScreenState.checkAuthStatus();
      await tester.pump();

      // Verify that isLoggedIn was checked
      verify(mockAuthService.isLoggedIn).called(1);
    });

    testWidgets('MockSplashScreen checks auth status for logged in buyer', 
        (WidgetTester tester) async {
      // Setup mock behavior
      when(mockAuthService.isLoggedIn).thenReturn(true);
      when(mockAuthService.isSeller).thenReturn(false);
      when(mockAuthService.isAdmin).thenReturn(false);
      when(mockAuthService.isSuperAdmin).thenReturn(false);

      // Create a widget reference we can access later
      late MockSplashScreenState splashScreenState;
      
      // Build the mock splash screen widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
              ChangeNotifierProvider<ThemeService>.value(value: themeService),
              ChangeNotifierProvider<LocaleService>.value(value: localeService),
            ],
            child: MockSplashScreen(
          key: const Key('splash'),
          skipInitialAuthCheck: true,
          onCreated: (state) {
            splashScreenState = state;
          },
        ),
          ),
        ),
      );

      // Manually trigger auth check
      splashScreenState.checkAuthStatus();
      await tester.pump();

      // Verify that isLoggedIn and role checks were performed
      verify(mockAuthService.isLoggedIn).called(1);
      verify(mockAuthService.isSeller).called(1);
    });
  });
}