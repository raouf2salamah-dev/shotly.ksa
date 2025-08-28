# Logger Utility

A comprehensive logging utility for Flutter applications that supports different logging levels and prevents sensitive data from being logged.

## Features

- Multiple log levels (debug, info, warning, error, critical)
- Automatic redaction of sensitive data
- Integration with Firebase Crashlytics
- Configurable minimum log level
- Tagged logs for easy filtering
- Build mode awareness (different behavior in debug vs. production)
- Conditional logging for debug/production environments

## Usage

### Basic Usage

```dart
// Create a logger instance with a tag
final logger = Logger('MyComponent');

// Log messages with different levels
logger.d('Debug message'); // Debug
logger.i('Info message');  // Info
logger.w('Warning message'); // Warning
logger.e('Error message', error: exception, stackTrace: stackTrace); // Error
logger.c('Critical message', error: exception, stackTrace: stackTrace); // Critical
```

### Handling Sensitive Data

```dart
// Log a message containing sensitive data
logger.logSensitive(
  LogLevel.info,
  'User data - Email: user@example.com, Phone: +1234567890, Card: 4111-1111-1111-1111',
  sensitiveData: {
    'email': 'user@example.com',
    'phone': '+1234567890',
    'card': '4111-1111-1111-1111',
  },
);

// Output will redact the sensitive information:
// [INFO] MyComponent: User data - Email: u**r@example.com, Phone: *******7890, Card: ****-****-****-1111
```

### Conditional Logging (Debug vs. Production)

```dart
// This replaces conditional compilation directives like:
// #if DEBUG
//   print("Debug: overlay added successfully")
// #else
//   // Production: log only minimal info
//   os_log("Overlay protection initialized", type: .info)
// #endif

logger.conditional(
  debugMessage: 'Debug: detailed diagnostic information',
  productionMessage: 'Feature initialized successfully',
  // Optional: customize log levels
  debugLevel: LogLevel.debug,
  productionLevel: LogLevel.info,
);
```

### Configuration

```dart
// Set minimum log level (messages below this level will be ignored)
Logger.setMinLogLevel(LogLevel.warning); // Only show warnings and above

// Enable/disable sending logs to Crashlytics
Logger.setSendToCrashlytics(true);
```

## Best Practices

1. **Use appropriate log levels**:
   - `debug`: Detailed information, useful during development
   - `info`: General information about application flow
   - `warning`: Potential issues that aren't errors
   - `error`: Runtime errors that don't crash the app
   - `critical`: Severe errors that might crash the app

2. **Always use `logSensitive()` for sensitive data**:
   - User credentials (emails, passwords)
   - Personal information (phone numbers, addresses)
   - Financial information (credit card numbers, account details)

3. **Set appropriate minimum log level for production**:
   ```dart
   Logger.setMinLogLevel(
     const bool.fromEnvironment('dart.vm.product') 
       ? LogLevel.warning 
       : LogLevel.debug
   );
   ```

4. **Use meaningful tags**:
   - Tags should identify the component or feature
   - Keep tags consistent across related classes
   - Example tags: 'AuthService', 'PaymentScreen', 'NetworkClient'

## Example

See the `logger_example.dart` file for a complete example of how to use the Logger utility.