# Certificate Pinning Implementation Guide

## Overview

Certificate pinning is a security technique that protects mobile applications from man-in-the-middle (MITM) attacks by validating that the server's certificate matches a known, trusted certificate. This guide explains how to implement, test, and maintain certificate pinning in our application.

## How Certificate Pinning Works

1. The app contains a list of trusted certificate fingerprints (SHA-256 hashes)
2. When connecting to a server, the app verifies the server's certificate against these trusted fingerprints
3. If the certificate doesn't match any trusted fingerprint, the connection is rejected
4. Our implementation includes both primary and backup fingerprints to support certificate rotation

## Implementation Details

### Certificate Pinning Service

Our application uses the `CertificatePinningService` class to manage certificate pinning:

```dart
// Singleton instance accessed through factory constructor
CertificatePinningService _instance = CertificatePinningService._internal();
factory CertificatePinningService() => _instance;
```

The service maintains a map of trusted fingerprints for each domain:

```dart
Map<String, Map<String, List<String>>> _certificateFingerprints = {
  'api.yourdomain.com': {
    'primary': [
      'AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D',
    ],
    'backup': [
      '5E:8F:16:52:78:84:DF:09:C0:3E:34:7D:9E:B6:1A:DF:5E:3B:7F:A6:0D:48:4A:C1:3D:B2:0E:79:56:E5:5A:44',
    ]
  },
  // Additional domains...
};
```

### Integration with Dio HTTP Client

The certificate pinning service integrates with the Dio HTTP client through the `configureDio` method:

```dart
void configureDio(Dio dio, {bool validateCertificates = true}) {
  if (kIsWeb) return; // Certificate pinning not applicable for web

  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Certificate validation logic
      return validateCertificate(cert, host);
    };
    return client;
  };

  // Add interceptors for handling certificate validation failures
  dio.interceptors.add(_createCertificateValidationInterceptor());
}
```

### Certificate Validation Logic

The core validation function checks if the certificate's fingerprint matches any of the trusted fingerprints:

```dart
bool validateCertificate(X509Certificate cert, String host) {
  // Get fingerprint from certificate
  final fingerprint = _getCertificateFingerprint(cert);
  
  // Get trusted fingerprints for this host
  final domainFingerprints = _certificateFingerprints[host];
  if (domainFingerprints == null) return false;
  
  // Check primary fingerprints
  if (domainFingerprints['primary']?.contains(fingerprint) == true) {
    return true;
  }
  
  // Check backup fingerprints
  if (domainFingerprints['backup']?.contains(fingerprint) == true) {
    return true;
  }
  
  // No match found
  _handleCertificateValidationFailure(host, fingerprint);
  return false;
}
```

## Generating Certificate Fingerprints

To generate a certificate fingerprint for your server, use the following OpenSSL command:

```bash
openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | \
openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | \
openssl dgst -sha256 -binary | openssl enc -base64
```

Alternatively, to generate a SHA-256 fingerprint in colon-separated format:

```bash
openssl x509 -in certificate.pem -noout -fingerprint -sha256
```

## Error Handling and User Experience

When certificate validation fails, our implementation:

1. Displays a user-friendly error message: "Secure connection failed. Please try again later or update the app."
2. Logs the validation failure for security monitoring
3. Implements graceful degradation for non-critical APIs by showing cached data when available

```dart
void _handleCertificateValidationFailure(String host, String fingerprint) {
  // Log the failure
  _logSecurityEvent('Certificate validation failed for $host');
  
  // Notify through callback if registered
  onCertificateValidationFailure?.call(host, fingerprint);
  
  // Set the failure flag
  _hasCertificateValidationFailed = true;
}
```

## Developer Mode

For easier local testing, a developer mode can be enabled in development builds:

```dart
// Enable developer mode (disables certificate pinning)
CertificatePinningService().setDeveloperMode(true);
```

This bypasses certificate validation, allowing developers to use tools like Charles Proxy or Burp Suite for debugging network requests.

**Important**: Developer mode must never be enabled in production builds.

## Testing Certificate Pinning

### Automated Testing

Use our CI/CD pipeline scripts to verify certificate pinning:

```bash
# From the project root directory
cd test_scripts
./ci_certificate_pinning_test.sh
```

This script will verify that:
- The app's pinned certificates match the expected certificates
- Both primary and backup fingerprints are correctly configured
- Certificate validation works as expected

### Manual Testing with Proxy Tools

1. Set up a proxy tool like Charles Proxy or Burp Suite
2. Configure your device to use the proxy
3. Try to access your API through the app
4. Verify that the app rejects the connection when certificate pinning is enabled
5. Enable developer mode and verify that connections succeed

## Certificate Rotation

Refer to the [Certificate Management Policy](/docs/security/certificate-management-policy.md) for detailed procedures on certificate rotation.

Key points:

1. Always maintain backup fingerprints in the app
2. Update the app with new fingerprints before deploying new certificates
3. Use the CI/CD pipeline for automated fingerprint updates

## Security Considerations

1. **Multiple Environments**: Configure different fingerprints for development, staging, and production environments
2. **Certificate Transparency**: Verify certificates appear in CT logs
3. **OCSP Checking**: Implement Online Certificate Status Protocol checking
4. **Graceful Degradation**: Allow non-critical APIs to function with cached data when certificate validation fails
5. **Regular Audits**: Perform quarterly audits of certificate fingerprints

## Troubleshooting

### Common Issues

1. **Certificate validation always fails**: Verify that you've generated the correct fingerprint for your server
2. **App works on some devices but not others**: Check if the device has a security proxy or VPN installed
3. **Certificate validation stops working**: The server certificate may have been rotated; update your trusted fingerprints

### Debugging

Enable verbose logging to see certificate validation details:

```dart
// Add this before making network requests
CertificatePinningService().enableVerboseLogging = true;
```

## Compliance

Our certificate pinning implementation helps meet the following security standards:

- OWASP MASVS V5.4: "The app either uses its own certificate store, or pins the endpoint certificate or public key"
- PCI DSS Requirement 4.1: "Use strong cryptography and security protocols"

## References

- [OWASP Certificate and Public Key Pinning](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
- [Android Network Security Configuration](https://developer.android.com/training/articles/security-config)
- [iOS App Transport Security](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)