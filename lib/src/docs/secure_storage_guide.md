# Secure Storage Guide

## Overview

This guide provides comprehensive information about secure storage options available in the app, focusing on two main implementations:

1. **Flutter Secure Storage**: Platform-specific encrypted storage for sensitive data
2. **Encrypted Hive**: Local NoSQL database with encryption for larger datasets

## Flutter Secure Storage

`flutter_secure_storage` provides a way to securely store key-value pairs using platform-specific security mechanisms:

- **iOS**: Data is stored in the Keychain with configurable accessibility options
- **Android**: Uses EncryptedSharedPreferences with StrongBox support on compatible devices
- **Web**: Uses localStorage with AES encryption (less secure than native platforms)

### Implementation

The app implements `SecureStorageService` as a wrapper around `flutter_secure_storage` with additional functionality:

```dart
class SecureStorageService {
  static final _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  // Basic operations with static methods
  static Future<void> write(String key, String value) => 
      _store.write(key: key, value: value);
  
  static Future<String?> read(String key) => _store.read(key: key);
  
  static Future<void> delete(String key) => _store.delete(key: key);
  
  // Note: Object storage methods are not included in the simplified static API
  // If needed, they can be implemented as extension methods or utility functions
  // Example implementation:
  /*
  static Future<void> writeObject(String key, Map<String, dynamic> value) async {
    final jsonString = json.encode(value);
    await write(key, jsonString);
  }
  
  static Future<Map<String, dynamic>?> readObject(String key) async {
    final jsonString = await read(key);
    if (jsonString == null) return null;
    
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON from secure storage: $e');
      return null;
    }
  }
  */
}
```

### When to Use Flutter Secure Storage

- **Sensitive Data**: Authentication tokens, API keys, credentials
- **Small Data Items**: Best for key-value pairs, not large datasets
- **High Security Requirements**: When platform-specific security features are needed

### Limitations

- Not suitable for large datasets (performance degrades with size)
- Limited to simple key-value storage
- No query capabilities

## Encrypted Hive

Hive is a lightweight, fast NoSQL database that can be encrypted for secure storage of larger datasets. The encryption is implemented using AES-256 in CBC mode.

### Implementation

To implement encrypted Hive storage, follow these steps:

1. **Generate an encryption key**:

```dart
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptedHiveService {
  static const String _secureStorageKey = 'hive_encryption_key';
  static const String _encryptedBoxName = 'encrypted_box';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box _encryptedBox;
  
  // Initialize encrypted Hive
  Future<void> init() async {
    // Get or generate encryption key
    final encryptionKey = await _getEncryptionKey();
    
    // Open encrypted box
    _encryptedBox = await Hive.openBox(
      _encryptedBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    
    print('Encrypted Hive box opened successfully!');
  }
  
  // Get encryption key from secure storage or generate a new one
  Future<List<int>> _getEncryptionKey() async {
    // Try to retrieve existing key
    String? keyString = await _secureStorage.read(key: _secureStorageKey);
    
    if (keyString == null) {
      // Generate a new key (32 bytes for AES-256)
      final key = Hive.generateSecureKey();
      
      // Store the key in secure storage
      await _secureStorage.write(
        key: _secureStorageKey,
        value: base64Url.encode(key),
      );
      
      return key;
    } else {
      // Decode existing key
      return base64Url.decode(keyString);
    }
  }
  
  // Save data to encrypted box
  Future<void> saveData(String key, dynamic value) async {
    await _encryptedBox.put(key, value);
  }
  
  // Get data from encrypted box
  dynamic getData(String key) {
    return _encryptedBox.get(key);
  }
  
  // Delete data from encrypted box
  Future<void> deleteData(String key) async {
    await _encryptedBox.delete(key);
  }
  
  // Clear all data
  Future<void> clearAll() async {
    await _encryptedBox.clear();
  }
  
  // Close box
  Future<void> close() async {
    await _encryptedBox.close();
  }
}
```

### When to Use Encrypted Hive

- **Larger Datasets**: When you need to store more than simple key-value pairs
- **Structured Data**: When you need to store complex objects with type adapters
- **Performance**: When you need fast access to encrypted data
- **Offline Data**: For secure offline storage of app data

### Limitations

- Encryption key management is critical (if lost, data cannot be recovered)
- Slightly slower than unencrypted Hive
- Requires more setup than flutter_secure_storage

## Comparison

| Feature | Flutter Secure Storage | Encrypted Hive |
|---------|------------------------|----------------|
| **Security Level** | Very High (platform-specific) | High (AES-256) |
| **Data Size** | Small (key-value pairs) | Large (NoSQL database) |
| **Performance** | Good for small data | Better for large data |
| **Complexity** | Simple to use | More complex setup |
| **Use Case** | Credentials, tokens, keys | User data, app state, caching |

## Best Practices

### Key Management

1. **Never hardcode encryption keys** in your application
2. **Store encryption keys** in flutter_secure_storage
3. **Consider key rotation** for long-term security
4. **Have a backup mechanism** for encryption keys

### Data Handling

1. **Minimize sensitive data storage** - only store what you need
2. **Clear sensitive data** when no longer needed
3. **Validate data** before storing and after retrieving
4. **Handle errors gracefully** to prevent data loss

### Security Considerations

1. **App Obfuscation**: Use code obfuscation to make reverse engineering harder
2. **Root/Jailbreak Detection**: Consider implementing detection for compromised devices
3. **Biometric Authentication**: Add an extra layer of security for accessing sensitive data
4. **Timeout Policies**: Implement automatic logout after inactivity

## Implementation Examples

### Storing Authentication Data

```dart
// Using SecureStorageService static methods

// Store authentication token
await SecureStorageService.write('auth_token', 'your-auth-token');
await SecureStorageService.write('refresh_token', 'your-refresh-token');
await SecureStorageService.write('token_expiry', DateTime.now().add(Duration(hours: 1)).toIso8601String());

// Retrieve authentication data
final token = await SecureStorageService.read('auth_token');
final refreshToken = await SecureStorageService.read('refresh_token');
final expiryString = await SecureStorageService.read('token_expiry');

if (token != null && refreshToken != null && expiryString != null) {
  final expiry = DateTime.parse(expiryString);
  
  // Use the authentication data
}
```

### Storing Encrypted User Preferences

```dart
// Using EncryptedHiveService
final encryptedStorage = EncryptedHiveService();
await encryptedStorage.init();

// Store user preferences
await encryptedStorage.saveData('user_preferences', {
  'theme': 'dark',
  'notifications': true,
  'language': 'en',
  'lastSync': DateTime.now().toIso8601String(),
});

// Retrieve user preferences
final preferences = encryptedStorage.getData('user_preferences');
if (preferences != null) {
  final theme = preferences['theme'];
  final notificationsEnabled = preferences['notifications'];
  
  // Use the preferences
}
```

## Troubleshooting

### Common Issues

1. **Key Not Found**: Ensure you're using the correct key and that it hasn't been deleted
2. **Encryption Errors**: Check that the encryption key is correctly generated and stored
3. **Performance Issues**: Consider using Hive for larger datasets instead of flutter_secure_storage
4. **Migration Problems**: When changing encryption schemes, implement proper migration strategies

### Debugging Tips

1. **Check Key Existence**: Verify if keys exist before attempting to read them
2. **Error Handling**: Implement proper try-catch blocks around storage operations
3. **Logging**: Add debug logging (in development only) to track storage operations

## Conclusion

Choosing the right secure storage option depends on your specific requirements:

- Use **flutter_secure_storage** for small, highly sensitive data like credentials and tokens
- Use **Encrypted Hive** for larger datasets, complex objects, and better performance

For maximum security, consider combining both approaches: store encryption keys in flutter_secure_storage and use those keys to encrypt data in Hive.