import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shotly/main.dart' as app;
import 'package:shotly/src/screens/shared/splash_screen.dart';
import 'package:shotly/src/screens/auth/onboarding_screen.dart';
import 'package:shotly/src/screens/auth/login_screen.dart';
import 'package:shotly/src/screens/auth/register_screen.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end app test', () {
    testWidgets('Verify app launch and navigation flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      
      // Wait for splash screen to appear and animations to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Wait for navigation to onboarding (assuming user is not logged in)
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Verify navigation to onboarding screen
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Test onboarding navigation - swipe through pages
      final pageView = find.byType(PageView);
      expect(pageView, findsOneWidget);

      // Swipe to next page
      await tester.drag(pageView, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Swipe to next page again
      await tester.drag(pageView, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Find and tap the 'Get Started' button
      await IntegrationTestHelpers.tapButtonWithText(tester, 'Get Started');

      // Verify navigation to login or registration screen
      await tester.pumpAndSettle();
      
      // Check if we're on the login screen
      if (find.byType(LoginScreen).evaluate().isNotEmpty) {
        expect(find.byType(LoginScreen), findsOneWidget);
        
        // Test navigation to registration screen
        final registerLink = find.text('Sign Up');
        if (registerLink.evaluate().isNotEmpty) {
          await tester.tap(registerLink);
          await tester.pumpAndSettle();
          expect(find.byType(RegisterScreen), findsOneWidget);
          
          // Go back to login
          final loginLink = find.text('Sign In');
          if (loginLink.evaluate().isNotEmpty) {
            await tester.tap(loginLink);
            await tester.pumpAndSettle();
            expect(find.byType(LoginScreen), findsOneWidget);
          }
        }
        
        // Test form validation
        final loginButton = find.text('Login');
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton);
          await tester.pumpAndSettle();
          
          // Should show validation errors
          expect(find.text('Please enter your email'), findsOneWidget);
          expect(find.text('Please enter your password'), findsOneWidget);
        }
      } else if (find.byType(RegisterScreen).evaluate().isNotEmpty) {
        expect(find.byType(RegisterScreen), findsOneWidget);
        
        // Test navigation to login screen
        final loginLink = find.text('Sign In');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink);
          await tester.pumpAndSettle();
          expect(find.byType(LoginScreen), findsOneWidget);
        }
      }
    });
    
    testWidgets('Test theme switching functionality', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Navigate through splash and onboarding
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // If we're on onboarding, complete it
      if (find.byType(OnboardingScreen).evaluate().isNotEmpty) {
        final pageView = find.byType(PageView);
        if (pageView.evaluate().isNotEmpty) {
          // Swipe to last page
          await tester.drag(pageView, const Offset(-300, 0));
          await tester.pumpAndSettle();
          await tester.drag(pageView, const Offset(-300, 0));
          await tester.pumpAndSettle();
          
          // Tap get started
          final getStartedButton = find.text('Get Started');
          if (getStartedButton.evaluate().isNotEmpty) {
            await tester.tap(getStartedButton);
            await tester.pumpAndSettle();
          }
        }
      }
      
      // Look for settings icon or menu
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
        
        // Look for theme toggle
        final themeToggle = find.text('Dark Mode');
        if (themeToggle.evaluate().isNotEmpty) {
          // Get current theme state
          final isDarkMode = Theme.of(tester.element(themeToggle)).brightness == Brightness.dark;
          
          // Toggle theme
          await tester.tap(themeToggle);
          await tester.pumpAndSettle();
          
          // Verify theme changed
          final newIsDarkMode = Theme.of(tester.element(themeToggle)).brightness == Brightness.dark;
          expect(newIsDarkMode, equals(!isDarkMode));
        }
      }
    });
  });
}