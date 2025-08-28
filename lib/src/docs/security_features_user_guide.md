# Security Features Guide

This guide provides an overview of the security features implemented in the app to protect your data and ensure secure communications.

## Certificate Pinning

Certificate pinning is a security technique that protects against man-in-the-middle (MITM) attacks by validating that the server's certificate matches a known, trusted certificate.

### How It Works

1. The app contains a pre-defined set of trusted certificate fingerprints
2. When connecting to our servers, the app verifies that the server's certificate matches one of these trusted fingerprints
3. If the certificate doesn't match, the connection is rejected, protecting you from potential attacks

### What This Means For You

- Your data is protected from eavesdropping or tampering during transmission
- The app can detect if someone is trying to intercept your communications
- You can be confident that you're connecting to our legitimate servers

## Secure Local Storage

Sensitive data stored on your device is protected using encryption and secure storage mechanisms.

### How It Works

1. Sensitive information (like authentication tokens) is stored in a secure, encrypted container
2. On iOS, this uses the Keychain
3. On Android, this uses the EncryptedSharedPreferences
4. Authentication tokens (access and refresh tokens) are stored with expiration times
   - Access tokens are short-lived (15 minutes by default)
   - Refresh tokens are longer-lived (7 days by default)

### What This Means For You

- Your sensitive information remains protected even if your device is compromised
- Data is encrypted using industry-standard algorithms
- Access to this data is restricted to our app only
- Authentication tokens automatically expire for enhanced security

## Device Security Checks

The app can detect if your device has been jailbroken (iOS) or rooted (Android), which may compromise the security of your data.

### How It Works

1. On startup, the app performs checks to detect if your device has been jailbroken or rooted
2. If detected, you'll receive a security warning

### What This Means For You

- You're informed about potential security risks on your device
- You can make informed decisions about using the app on potentially compromised devices

## API Security

All communications with our servers are protected using multiple security layers.

### How It Works

1. All API requests use HTTPS with TLS 1.2 or higher
2. Certificate pinning (as described above) verifies server authenticity
3. Authentication tokens are securely managed and refreshed

### What This Means For You

- Your data is encrypted during transmission
- The app can detect and prevent connection to fraudulent servers
- Your authentication is managed securely

## Security Best Practices

For the best security experience:

1. Keep your device's operating system and the app updated to the latest version
2. Use a strong device passcode or biometric authentication
3. Avoid using the app on jailbroken or rooted devices
4. Be cautious when connecting to public Wi-Fi networks
5. Log out of the app when using shared devices

## Questions or Concerns?

If you have any questions about our security features or notice any suspicious behavior, please contact our support team immediately.

## New Security Enhancements

### Protected Content

We've enhanced the security of your sensitive information with new protection features:

- **Screenshot and Screen Recording Prevention**: Screenshots and app switcher previews of protected content are now automatically disabled. This prevents accidental or intentional capture of sensitive information.

- **Background Protection**: When you switch to another app, sensitive content is automatically hidden to prevent it from appearing in your device's app switcher.

### Biometric Authentication

To further protect your data:

- **Automatic Timeout**: After a period of inactivity (when the app is in the background), you may be required to authenticate again before accessing sensitive information.

- **Biometric Options**: Depending on your device, you can use fingerprint, face recognition, or other biometric methods for quick and secure authentication.

## Customizing Your Security Settings

You can personalize your security experience in the app settings:

1. Go to **Settings** → **Security Examples** → **Inactivity Timeout**
2. Adjust the following options:
   - **Timeout Duration**: Choose how long the app should wait before requiring re-authentication (1-15 minutes)
   - **Biometric Authentication**: Toggle whether biometric authentication is required after timeout

## Why These Features Matter

These security enhancements help protect your sensitive information from:

- Accidental exposure when switching between apps
- Unauthorized access if you leave your device unattended
- Screen capture of confidential content

Your privacy and data security are our top priorities. These features have been implemented following industry best practices to provide robust protection while maintaining a seamless user experience.