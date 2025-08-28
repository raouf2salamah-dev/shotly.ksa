import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Helper methods for integration tests
class IntegrationTestHelpers {
  /// Finds a widget by key and scrolls until it's visible
  static Future<void> scrollUntilVisible({
    required WidgetTester tester,
    required Finder scrollable,
    required Finder item,
    double delta = -300.0,
    int maxScrolls = 20,
  }) async {
    for (int i = 0; i < maxScrolls; i++) {
      if (item.evaluate().isNotEmpty && item.evaluate().first.size != null) {
        return;
      }
      await tester.drag(scrollable, Offset(0, delta));
      await tester.pumpAndSettle();
    }
    throw Exception('Could not find $item after $maxScrolls scrolls');
  }

  /// Waits for a specific duration
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Takes a screenshot (only works on physical devices)
  static Future<void> takeScreenshot(
    IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester,
    String name,
  ) async {
    if (binding is LiveTestWidgetsFlutterBinding) {
      await binding.takeScreenshot(name);
    }
  }

  /// Finds and taps a button with specific text
  static Future<void> tapButtonWithText(
    WidgetTester tester,
    String text,
  ) async {
    final button = find.text(text);
    expect(button, findsOneWidget, reason: 'Button with text "$text" not found');
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// Enters text into a field found by key
  static Future<void> enterTextByKey(
    WidgetTester tester,
    Key key,
    String text,
  ) async {
    final field = find.byKey(key);
    expect(field, findsOneWidget, reason: 'Field with key $key not found');
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }
}