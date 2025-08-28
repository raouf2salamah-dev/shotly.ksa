# Secure Storage Implementation

## Overview

This package provides robust secure storage solutions for Flutter applications, offering two complementary approaches:

1. **Flutter Secure Storage**: For small, highly sensitive data (tokens, credentials)
2. **Encrypted Hive**: For larger datasets with AES-256 encryption

## Features

- **Platform-specific security**: Uses Keychain on iOS and EncryptedSharedPreferences on Android
- **AES-256 encryption**: Military-grade encryption for Hive database
- **Secure key management**: Encryption keys stored in platform secure storage
- **Comprehensive API**: Simple methods for storing various data types
- **Demo application**: Interactive demo to test both storage options

## Quick Start

### 1. Initialize Services

```dart
// Initialize regular Hive (for caching)
await HiveService.init();

// Initialize encrypted Hive
final encryptedHive = EncryptedHiveService();
await encryptedHive.init();
```

### 2. Using Flutter Secure Storage

```dart
// Store sensitive data
await SecureStorageService.write('api_key', 'your-secret-api-key');

// Retrieve data
final apiKey = await SecureStorageService.read('api_key');

// Note: Object storage methods are not part of the simplified static API
// For storing complex objects, store individual properties:
await SecureStorageService.write('username', 'user123');
await SecureStorageService.write('token', 'auth-token-here');
await SecureStorageService.write('expiry', DateTime.now().add(Duration(days: 1)).toIso8601String());

// Retrieve individual properties
final username = await SecureStorageService.read('username');
final token = await SecureStorageService.read('token');
final expiryString = await SecureStorageService.read('expiry');
```

### 3. Using Encrypted Hive

```dart
final encryptedHive = EncryptedHiveService();
await encryptedHive.init();

// Store data
await encryptedHive.saveData('user_profile', {
  'name': 'John Doe',
  'email': 'john@example.com',
  'preferences': {
    'theme': 'dark',
    'notifications': true
  }
});

// Retrieve data
final userProfile = encryptedHive.getData('user_profile');

// Check if data exists
final hasProfile = encryptedHive.containsKey('user_profile');

// Delete data
await encryptedHive.deleteData('user_profile');
```

### 4. Using SecureUserData (Combined Approach)

The `SecureUserData` class demonstrates a best practice approach by using both storage options together:

```dart
final userData = SecureUserData();
await userData.init();

// Store authentication data (in flutter_secure_storage)
await userData.saveAuthToken('your-auth-token');
await userData.saveUserId('user123');

// Store profile data (in encrypted Hive)
await userData.saveUserProfile({
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Store preferences (in encrypted Hive)
await userData.saveUserPreferences({
  'theme': 'dark',
  'notifications': true,
});

// Add user activity (in encrypted Hive)
await userData.addUserActivity({
  'action': 'login',
  'device': 'iPhone',
});

// Export all user data (for GDPR compliance)
final exportedData = await userData.exportUserData();

// Clear all user data (for account deletion)
await userData.clearAllUserData();
```

## Demo Application

The package includes a demo application that showcases both storage options:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SecureStorageScreen(),
  ),
);
```

## Security Best Practices

1. **Never hardcode encryption keys** in your application
2. **Minimize sensitive data storage** - only store what you need
3. **Clear sensitive data** when no longer needed
4. **Implement timeout policies** for sensitive data access
5. **Consider biometric authentication** for accessing sensitive data
6. **Test on real devices** to ensure platform-specific security features work correctly

## Documentation

For more detailed information, see the comprehensive guide:

- [Secure Storage Guide](secure_storage_guide.md)

## Dependencies

- `flutter_secure_storage: ^8.0.0`
- `hive: ^2.2.3`
- `hive_flutter: ^1.1.0`