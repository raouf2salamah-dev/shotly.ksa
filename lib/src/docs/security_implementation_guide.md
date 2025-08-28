# Security Implementation Guide

## Overview

This document provides a comprehensive guide to the security features implemented in the app. It covers certificate pinning, secure storage, device security checks, and API security.

## Certificate Pinning

Certificate pinning is implemented to prevent man-in-the-middle (MITM) attacks by validating that the server's certificate matches a predefined hash.

### Implementation Details

- **SecureHttpClient**: Uses Dio with certificate validation in the `badCertificateCallback`
- **Certificate Hash Generation**: Use the following command to generate the hash for your server:
  ```bash
  openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  ```
- **Configuration**: Add the generated hash to the `_validCertificateFingerprints` map in `SecureHttpClient`

### Testing Certificate Pinning

1. Configure a proxy like Charles or Burp Suite
2. Install the proxy's certificate on your device
3. Attempt to make API requests through the proxy
4. Verify that requests fail when certificate pinning is enabled

## Secure Storage

Sensitive data is stored securely using platform-specific encryption mechanisms.

### Implementation Details

- **SecureStorageService**: Uses `flutter_secure_storage` for encrypted storage
- **iOS**: Data is stored in the Keychain with `first_unlock` accessibility
- **Android**: Uses EncryptedSharedPreferences with StrongBox support on compatible devices

### Usage

```dart
// Store data securely
await SecureStorageService.write('api_key', 'your-api-key');

// Retrieve data securely
final apiKey = await SecureStorageService.read('api_key');
```

## Device Security Checks

The app checks for jailbroken/rooted devices to warn users about potential security risks.

### Implementation Details

- **DeviceSecurityService**: Uses `flutter_jailbreak_detection` to detect compromised devices
- **Warning Dialog**: Shows a warning when a jailbroken/rooted device is detected

### Usage

```dart
// Check if device is compromised
final isCompromised = await SecurityService().isDeviceCompromised();

// Show warning if needed
await SecurityService().checkAndShowDeviceSecurityWarning(context);
```

## API Security

API requests are secured with certificate pinning, proper error handling, and secure authentication.

### Implementation Details

- **SecureApiService**: Implements API calls with certificate pinning and proper error handling
- **Authentication**: Tokens are stored securely and transmitted securely
- **Error Handling**: Specific exceptions for different security scenarios

## Security Best Practices

1. **Regular Updates**: Keep dependencies updated to patch security vulnerabilities
2. **Certificate Rotation**: Plan for certificate rotation and have a backup mechanism
3. **Minimal Permissions**: Request only the permissions your app needs
4. **Secure Coding**: Follow secure coding practices to prevent common vulnerabilities
5. **Security Testing**: Regularly test your app's security with penetration testing

## Troubleshooting

### Certificate Pinning Issues

- If legitimate API requests fail, verify that the certificate hash is correct
- If the server's certificate changes, update the hash in the app

### Device Security Warning

- The warning is shown only once per app session
- Users can proceed at their own risk

## Future Enhancements

1. **Certificate Transparency**: Implement certificate transparency checks
2. **App Attestation**: Add SafetyNet/App Attestation for additional security
3. **Biometric Authentication**: Add biometric authentication for sensitive operations
4. **Runtime Integrity Checks**: Add checks for app tampering and hooking frameworks