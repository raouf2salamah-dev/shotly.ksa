# Certificate Pinning Implementation Guide

## Overview

Certificate pinning is a security technique that helps protect your app from man-in-the-middle attacks by validating that the server's certificate matches a known, trusted certificate. This guide explains how to use and test the certificate pinning implementation in our app.

## How Certificate Pinning Works

1. The app contains a list of trusted certificate fingerprints (SHA-256 hashes)
2. When connecting to a server, the app verifies the server's certificate against these trusted fingerprints
3. If the certificate doesn't match any trusted fingerprint, the connection is rejected

## Generating Certificate Fingerprints

To generate a certificate fingerprint for your server, use the following OpenSSL command:

```bash
openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | \
openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | \
openssl dgst -sha256 -binary | openssl enc -base64
```

This will output a base64-encoded SHA-256 hash of the server's public key. Add the prefix `sha256/` to this hash to create a complete fingerprint.

## Configuring Certificate Pinning

The `SecureHttpClient` class handles certificate pinning in our app. It supports multiple environments (production, staging, development) with different sets of trusted certificates.

### Setting the Environment

```dart
// Set the environment for certificate validation
SecureHttpClient.setEnvironment('production'); // or 'staging', 'development'
```

### Handling Certificate Validation Failures

You can set a callback to be notified when certificate validation fails:

```dart
SecureHttpClient.onCertificateValidationFailure = (host, fingerprint) {
  // Show a user-friendly message
  print('Security alert: Invalid certificate detected for $host');
  print('Received fingerprint: $fingerprint');
};
```

## Testing Certificate Pinning

### Automated Testing

Use the built-in test method to verify certificate pinning is working correctly:

```dart
final testResult = await SecureHttpClient.testCertificatePinning('https://api.yourdomain.com');
print(testResult);
```

### Manual Testing with Proxy Tools

1. Set up a proxy tool like Charles Proxy or Burp Suite
2. Configure your device to use the proxy
3. Try to access your API through the app
4. Verify that the app rejects the connection (the proxy acts as a man-in-the-middle)

## Important Considerations

### Certificate Rotation

Server certificates expire and need to be rotated. Plan for this by:

1. Including multiple fingerprints in your trusted list
2. Having a mechanism to update the app when certificates change
3. Implementing a backup validation method for emergencies

### Multiple Environments

Different environments (development, staging, production) may have different certificates. Configure fingerprints for each environment.

### User Experience

When certificate validation fails:

1. Show a clear, non-technical error message to the user
2. Provide guidance on what to do next
3. Consider logging the event for security monitoring

## Example Implementation

See the `CertificatePinningExample` class in the examples directory for a complete implementation example.

## Troubleshooting

### Common Issues

1. **Certificate validation always fails**: Verify that you've generated the correct fingerprint for your server
2. **App works on some devices but not others**: Check if the device has a security proxy or VPN installed
3. **Certificate validation stops working**: The server certificate may have been rotated; update your trusted fingerprints

### Debugging

Enable verbose logging to see certificate validation details:

```dart
// Add this before making network requests
SecureHttpClient.enableVerboseLogging = true;
```

## Security Best Practices

1. **Keep fingerprints up to date**: Regularly check and update your trusted fingerprints
2. **Use multiple fingerprints**: Include backup fingerprints for certificate rotation
3. **Test thoroughly**: Verify certificate pinning works on all platforms and environments
4. **Handle failures gracefully**: Provide clear error messages and recovery options
5. **Monitor for security events**: Log and analyze certificate validation failures