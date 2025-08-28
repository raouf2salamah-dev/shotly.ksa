# Automated Testing for Digital Content Marketplace

This directory contains automated tests for the Digital Content Marketplace application. The tests are organized into widget tests and integration tests to ensure the application functions correctly.

## Test Structure

### Widget Tests

Widget tests verify that individual widgets render correctly and respond to user interactions as expected.

- `widget_test.dart`: Basic app initialization tests
- `login_screen_test.dart`: Tests for the login screen functionality
- `splash_screen_test.dart`: Tests for the splash screen and navigation flow
- `theme_service_test.dart`: Tests for theme switching functionality
- `auth_service_test.dart`: Tests for authentication service
- `locale_service_test.dart`: Tests for language switching functionality
- `custom_button_test.dart`: Tests for the custom button widget
- `custom_text_field_test.dart`: Tests for the custom text field widget

### Integration Tests

Integration tests verify that different parts of the application work together correctly.

- `integration_test/app_test.dart`: End-to-end test for app launch and navigation flow

### Test Helpers

- `test_helpers.dart`: Utility functions and mock classes to assist with testing

## Running Tests

### Widget Tests

To run all widget tests:

```bash
flutter test
```

To run a specific widget test:

```bash
flutter test test/login_screen_test.dart
```

### Integration Tests

To run integration tests:

```bash
flutter test integration_test/app_test.dart
```

## Generating Mock Classes

Some tests use mock classes generated with the Mockito package. To generate the mock classes, run:

```bash
flutter pub run build_runner build
```

## Test Coverage

To generate a test coverage report:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Then open `coverage/html/index.html` in a browser to view the coverage report.

## Best Practices

1. Keep tests independent and isolated
2. Use descriptive test names
3. Group related tests together
4. Mock external dependencies
5. Test both success and failure cases
6. Run tests before submitting code changes