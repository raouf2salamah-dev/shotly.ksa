# Signed API Request Guide

## Overview

This guide explains the implementation of HMAC-SHA256 request signing for secure client-server communication in Flutter applications. Request signing adds an additional layer of security by ensuring that API requests are authentic and have not been tampered with during transmission.

## Security Warning

⚠️ **Important Security Consideration**: While this implementation uses secure storage for the signing key, it's important to understand that client-side secrets (including signing keys) may still be extractable on rooted or jailbroken devices, or through sophisticated attacks. Request signing should be considered as one layer in a defense-in-depth strategy, not as the sole security mechanism.

## How It Works

1. **Device Registration**: During device registration, the server generates a unique signing key for the device and sends it to the client.

2. **Secure Storage**: The client stores this signing key in secure storage using platform-specific encryption.

3. **Request Signing**: For each API request:
   - The client generates a timestamp
   - The client creates a signature by computing HMAC-SHA256 of `path|body|timestamp` (using pipe delimiter) using the stored signing key
   - The signature (base64-encoded) and timestamp are included in the request headers

4. **Server Verification**: The server:
   - Retrieves the device's signing key from its database
   - Recreates the signature using the same method
   - Compares the signatures to verify authenticity
   - Checks the timestamp to prevent replay attacks

## Implementation Components

### 1. SecureStorageService

Provides methods for securely storing and retrieving the device signing key, as well as generating request signatures:

- `storeDeviceSigningKey(String key)`: Securely stores the device-specific signing key
- `getDeviceSigningKey()`: Retrieves the stored signing key
- `signRequest(String path, String body, String timestamp)`: Generates HMAC-SHA256 signature

### 2. SignedApiService

Handles API requests with automatic signing:

- Automatically adds timestamp and signature headers to all requests
- Provides methods for common HTTP operations (GET, POST, PUT, DELETE)
- Includes utilities for managing the device signing key

## Usage Example

```dart
// Initialize the service
final apiService = SignedApiService();
apiService.initialize(baseUrl: 'https://api.example.com');

// Store the device signing key (received from server during registration)
await apiService.storeDeviceSigningKey('server-provided-signing-key');

// Make signed API requests
final response = await apiService.get('/protected-resource');
```

## Best Practices

1. **Key Generation**: Always generate signing keys on the server, never on the client.

2. **Timestamp Validation**: The server should reject requests with timestamps that are too old (e.g., more than 5 minutes) to prevent replay attacks.

3. **Key Rotation**: Implement a mechanism to periodically rotate signing keys.

4. **Defense in Depth**: Use request signing alongside other security measures like TLS, token-based authentication, and proper authorization checks.

5. **Monitoring**: Implement server-side monitoring to detect unusual patterns of API usage that might indicate an attack.

## Limitations

- This implementation does not protect against attacks where the attacker has full control of the client device.
- The security of this approach depends on the security of the device's secure storage implementation.
- Request signing does not replace proper authentication and authorization mechanisms.

## Server-Side Implementation Considerations

The server-side implementation should:

1. Store device signing keys securely in a database
2. Validate request signatures for all protected endpoints
3. Check timestamp freshness to prevent replay attacks
4. Implement rate limiting to prevent brute force attacks
5. Log failed signature verifications for security monitoring