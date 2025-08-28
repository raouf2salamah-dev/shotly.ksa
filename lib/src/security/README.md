# Security Module

## Overview
This module provides security features for the application, including secure storage of sensitive data, API request signing, token management, and device integrity verification.

## Components

### SecureStorageService
Provides encrypted storage for sensitive data using platform-specific security features:
- iOS: Keychain
- Android: EncryptedSharedPreferences

### AuthInterceptor
A Dio HTTP client interceptor that handles authentication tokens, including:
- Automatically adding access tokens to requests
- Refreshing expired tokens when receiving 401 Unauthorized responses
- Securely storing new tokens after refresh

### SignedApiService
Implements HMAC-SHA256 request signing for secure client-server communication:
- Automatically signs all outgoing API requests
- Uses a device-specific signing key stored in secure storage
- Adds timestamp to prevent replay attacks
- Provides a complete API client with common HTTP methods

### DeviceIntegrity
Provides a simple way to check if a device has been compromised:
- Detects jailbroken/rooted devices
- Detects if developer mode is enabled
- Returns a single boolean indicating if the device is compromised

### DeviceSecurityUtils
Utility class that provides convenient methods for device security checks:
- Checks device integrity and shows warning dialog in one call
- Supports feature restriction for compromised devices
- Customizable warning messages and actions

### SecurityDialogManager
Manages the display of security-related dialogs:
- Shows security introduction dialog only once
- Persists dialog display status using SharedPreferences
- Provides methods to check and reset dialog status

## Usage

### Secure Storage
```dart
// Store a token
await SecureStorageService.write('access_token', 'your-token-value');

// Retrieve a token
final token = await SecureStorageService.read('access_token');

// Delete a token
await SecureStorageService.delete('access_token');
```

### Auth Interceptor
```dart
// Create a Dio instance with the AuthInterceptor
final dio = Dio();
dio.interceptors.add(AuthInterceptor(dio));

// Make authenticated requests
final response = await dio.get('/protected-resource');
// The interceptor automatically adds the token and handles refresh if needed
```

### Device Integrity
```dart
// Check if device is compromised (jailbroken/rooted or developer mode enabled)
final isCompromised = await DeviceIntegrity.isCompromised();

// Take action based on device integrity status
if (isCompromised) {
  // Show warning to user or take appropriate security measures
  showSecurityWarningDialog(context);
}
```

### Device Security Utils
```dart
// Check device integrity, show warning dialog, and restrict features in one call
await DeviceSecurityUtils.checkDeviceIntegrityAndWarn(
  context: context,
  title: 'Security Warning', // Optional custom title
  message: 'This device appears to be compromised', // Optional custom message
  buttonText: 'I Understand', // Optional custom button text
  onCompromisedDevice: () {
    // Optional callback to restrict features
    disableUploads();
    disablePayments();
  },
);
```

### Security Dialog Manager
```dart
// Show security introduction dialog if it hasn't been shown before
await SecurityDialogManager.showSecurityIntroDialogIfNeeded(
  context: context,
  dialogBuilder: () => SecurityIntroDialog(),
);

// Check if the dialog has been shown before
final hasBeenShown = await SecurityDialogManager.hasSecurityDialogBeenShown();

// Reset dialog status (useful after app updates with new security features)
await SecurityDialogManager.resetSecurityDialogShownStatus();

// Show a dialog for a sensitive screen if it hasn't been shown in the current session
await SecurityDialogManager.showSensitiveScreenDialogInSession(
  context,
  'payment_screen', // Unique key for this sensitive screen
  () => AlertDialog(
    title: const Text('Payment Security'),
    content: const Text('You are accessing sensitive payment information.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
  ),
);

// Reset all session-based dialogs (e.g., when logging out)
SecurityDialogManager.resetSessionDialogs();

// Check if a sensitive screen dialog has been shown in the current session
final hasShownPaymentDialog = SecurityDialogManager.hasDialogBeenShownInSession('payment_screen');
```

### Signed API Service
```dart
// Initialize the service
final apiService = SignedApiService();
apiService.initialize(baseUrl: 'https://api.example.com');

// Store the device signing key (received from server during registration)
await apiService.storeDeviceSigningKey('server-provided-signing-key');

// Make signed API requests
final response = await apiService.get('/protected-resource');
// The request is automatically signed with HMAC-SHA256
```

## Security Best Practices
- Access tokens are short-lived (typically 15 minutes)
- Refresh tokens are longer-lived (typically 7 days)
- Tokens are stored in platform-specific secure storage
- Token refresh happens automatically when access tokens expire
- Failed authentication automatically clears tokens
- API requests are signed with HMAC-SHA256 to prevent tampering
- Request timestamps are included to prevent replay attacks
- Device-specific signing keys are stored in secure storage

## Security Considerations

⚠️ **Important Warning**: While these implementations follow security best practices, it's important to understand that client-side security has inherent limitations:

1. **Client-side secrets** (including signing keys) may be extractable on rooted or jailbroken devices, or through sophisticated attacks.

2. **Secure storage** implementations vary by platform and may have different security characteristics.

3. These security measures should be part of a **defense-in-depth strategy** that includes server-side validation, proper authentication and authorization, and other security controls.

## Documentation

- [Signed API Guide](signed_api_guide.md) - Detailed documentation on the request signing implementation
- [Server-Side Verification Example](server_side_verification_example.md) - Example server implementations for verifying signed requests
- [Auth Interceptor Guide](auth_interceptor_guide.md) - Guide for using the auth interceptor for token management