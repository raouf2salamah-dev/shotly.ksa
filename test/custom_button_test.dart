import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotly/src/widgets/custom_button.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('CustomButton renders correctly with text', (WidgetTester tester) async {
      const buttonText = 'Test Button';
      
      // Build the CustomButton widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: buttonText,
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      // Verify that the button is displayed with the correct text
      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('CustomButton calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;
      
      // Build the CustomButton widget with an onPressed callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'Press Me',
                onPressed: () {
                  wasPressed = true;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(CustomButton));
      
      // Verify that the callback was called
      expect(wasPressed, isTrue);
    });

    testWidgets('CustomButton applies correct styling', (WidgetTester tester) async {
      // Build the CustomButton widget with custom styling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'Styled Button',
                onPressed: () {},
                backgroundColor: Colors.red,
                textColor: Colors.white,
              ),
            ),
          ),
        ),
      );

      // Find the button
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      // Verify styling properties
      final button = tester.widget<ElevatedButton>(buttonFinder);
      final buttonStyle = button.style;
      
      // Check background color
      final backgroundColor = buttonStyle?.backgroundColor?.resolve({});
      expect(backgroundColor, equals(Colors.red));
      
      // Check text color
      final foregroundColor = buttonStyle?.foregroundColor?.resolve({});
      expect(foregroundColor, equals(Colors.white));
    });

    testWidgets('CustomButton is disabled when onPressed is null', (WidgetTester tester) async {
      // Build the CustomButton widget with null onPressed
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'Disabled Button',
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      // Find the button
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      // Verify the button is disabled
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });
  });
}