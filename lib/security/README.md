# Security Architecture

This document provides an overview of the security architecture implemented in this application.

## Core Security Components

### Certificate Pinning

- **Implementation**: `dio_pinning.dart`
- **Purpose**: Prevents man-in-the-middle attacks by validating server certificates against known fingerprints
- **Features**:
  - SHA-256 certificate fingerprint validation
  - Support for multiple domains
  - Configurable validation behavior
  - Callback for handling validation failures

### Secure Storage

- **Implementation**: `secure_storage.dart`
- **Purpose**: Provides encrypted storage for sensitive data
- **Features**:
  - Platform-specific secure storage (Keychain on iOS, KeyStore on Android)
  - Methods for reading, writing, and deleting secure data
  - Specialized methods for storing authentication tokens and device signing keys

### Device Integrity

- **Implementation**: `device_integrity.dart`
- **Purpose**: Detects if a device is compromised (jailbroken/rooted) or has developer mode enabled
- **Features**:
  - Detection of jailbroken/rooted devices
  - Detection of developer mode
  - Detailed integrity report

## Network Security

### Authentication Interceptor

- **Implementation**: `auth_interceptor.dart`
- **Purpose**: Manages authentication tokens and handles token refresh
- **Features**:
  - Automatic token refresh on 401 Unauthorized responses
  - Token storage in secure storage
  - Prevention of refresh loops

### Request Signing

- **Implementation**: `request_signer.dart`
- **Purpose**: Signs API requests with HMAC-SHA256 to prevent tampering
- **Features**:
  - HMAC-SHA256 request signing
  - Timestamp validation to prevent replay attacks
  - Signature verification for testing

## Integration

### Security Bootstrap

- **Implementation**: `security_bootstrap.dart`
- **Purpose**: Centralizes security initialization
- **Features**:
  - One-line initialization of all security features
  - Configuration options for different environments
  - Security reporting

### Security Intro Dialog

- **Implementation**: `security_intro.dart`
- **Purpose**: Informs users about the app's security features
- **Features**:
  - Visual representation of security status
  - Detailed explanations of security features

## Platform-Specific Configuration

### Android

- **Implementation**: `AndroidManifest.xml` and `network_security_config.xml`
- **Features**:
  - `usesCleartextTraffic="false"` to prevent unencrypted connections
  - Certificate pinning via `network_security_config.xml`
  - Domain-specific security configuration

### iOS

- **Implementation**: `Info.plist`
- **Features**:
  - App Transport Security (ATS) configuration
  - Certificate transparency
  - TLS version requirements
  - Domain-specific exceptions

## Usage Example

See `examples/security_features_example.dart` for a complete example of how to use the security features in a Flutter widget.

## Best Practices

1. **Always initialize security features early** in the application lifecycle
2. **Use certificate pinning in production** but consider disabling it in development
3. **Regularly rotate signing keys** and update certificate fingerprints
4. **Handle security failures gracefully** with appropriate user feedback
5. **Test security features thoroughly** with both positive and negative test cases