import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shotly/src/services/theme_service.dart';

void main() {
  const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    secureStorageChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return null;
      }
      if (methodCall.method == 'write') {
        return null;
      }
      throw MissingPluginException('No implementation found for method ${methodCall.method}');
    });
  });

  tearDown(() {
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  group('ThemeService Tests', () {
    late ThemeService themeService;

    setUp(() {
      themeService = ThemeService();
    });

    test('Default theme should be system', () {
      expect(themeService.themeMode, equals(ThemeMode.system));
    });

    test('Setting theme to dark updates themeMode', () {
      themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeMode, equals(ThemeMode.dark));
    });

    test('Setting theme to light updates themeMode', () {
      themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, equals(ThemeMode.light));
    });

    test('Toggle theme switches between light and dark', () {
      // Start with light theme
      themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, equals(ThemeMode.light));

      // Toggle to dark
      themeService.toggleTheme();
      expect(themeService.themeMode, equals(ThemeMode.dark));

      // Toggle back to light
      themeService.toggleTheme();
      expect(themeService.themeMode, equals(ThemeMode.light));
    });

    testWidgets('isDarkMode returns correct value', (WidgetTester tester) async {
      themeService.setThemeMode(ThemeMode.light);
      await tester.pumpWidget(Builder(builder: (context) {
        expect(themeService.isDarkMode(context), isFalse);
        return Container();
      }));

      themeService.setThemeMode(ThemeMode.dark);
      await tester.pumpWidget(Builder(builder: (context) {
        expect(themeService.isDarkMode(context), isTrue);
        return Container();
      }));

      themeService.setThemeMode(ThemeMode.system);
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light),
        child: Builder(builder: (context) {
          expect(themeService.isDarkMode(context), isFalse);
          return Container();
        }),
      ));

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark),
        child: Builder(builder: (context) {
          expect(themeService.isDarkMode(context), isTrue);
          return Container();
        }),
      ));
    });
  });
}