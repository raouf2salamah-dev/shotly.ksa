import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotly/src/widgets/custom_text_field.dart';

void main() {
  group('CustomTextField Widget Tests', () {
    testWidgets('CustomTextField renders correctly with label', (WidgetTester tester) async {
      const labelText = 'Email';
      
      // Build the CustomTextField widget
      await tester.pumpWidget(
        MaterialApp(
    home: Scaffold(
      body: Center(
        child: CustomTextField(
          controller: TextEditingController(),
          hintText: 'Enter email',
          labelText: labelText,
        ),
      ),
    ),
  ),
      );

      // Verify that the text field is displayed with the correct label
      expect(find.text(labelText), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('CustomTextField shows error message when validation fails', (WidgetTester tester) async {
      final controller = TextEditingController();
      const errorMessage = 'This field is required';
      
      // Build the CustomTextField widget with validation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Center(
                child: CustomTextField(
                  controller: controller,
                  hintText: 'Enter value',
            labelText: 'Required Field',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return errorMessage;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Trigger validation by entering text and then clearing it
      await tester.enterText(find.byType(TextFormField), 'some text');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      // Verify that the error message is displayed
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('CustomTextField obscures text when isPassword is true', (WidgetTester tester) async {
      // Build the CustomTextField widget with password configuration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomTextField(
                controller: TextEditingController(),
                hintText: 'Enter password',
          labelText: 'Password',
          isPassword: true,
              ),
            ),
          ),
        ),
      );

      // Find the text field
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Verify that the text is obscured
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.obscureText, isTrue);

      // Verify that the visibility toggle icon is present
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('CustomTextField toggles password visibility when icon is tapped', (WidgetTester tester) async {
      // Build the CustomTextField widget with password configuration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomTextField(
                controller: TextEditingController(),
                hintText: 'Enter password',
                labelText: 'Password',
                isPassword: true,
              ),
            ),
          ),
        ),
      );

      // Find the visibility toggle icon and tap it
      final iconButtonFinder = find.byType(IconButton);
      expect(iconButtonFinder, findsOneWidget);
      await tester.tap(iconButtonFinder);
      await tester.pump();

      // Verify that the text is now visible
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);

      // Tap again to toggle back
      await tester.tap(iconButtonFinder);
      await tester.pump();

      // Verify that the text is obscured again
      final updatedTextField = tester.widget<TextField>(find.byType(TextField));
      expect(updatedTextField.obscureText, isTrue);
    });
  });
}