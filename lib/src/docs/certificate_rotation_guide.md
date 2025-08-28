# Certificate Rotation Guide

## Overview

This guide explains how to manage certificate rotation in the app to ensure secure API communication without disruption when server certificates change.

## Why Certificate Rotation Matters

Server TLS certificates typically expire after 1-2 years and need to be replaced. Without proper handling, this can break certificate pinning in your app, causing all API requests to fail until users update to a version with the new certificate fingerprints.

## Our Certificate Pinning Implementation

Our implementation stores both primary (current) and backup (future) certificate fingerprints:

```dart
// In CertificatePinningService class
static final Map<String, Map<String, dynamic>> _certificateFingerprints = {
  'api.yourdomain.com': {
    // Primary (current) certificate fingerprint
    'primary': 'CURRENT_CERTIFICATE_FINGERPRINT',
    // Backup fingerprints for certificate rotation
    'backup': [
      'NEXT_CERTIFICATE_FINGERPRINT',
    ]
  },
};
```

## Certificate Rotation Process

### 1. Preparation (At Least 2 Weeks Before Expiry)

1. **Generate the new certificate** for your API domain
2. **Extract the fingerprint** of the new certificate:
   ```bash
   openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | \
   openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | \
   openssl dgst -sha256 -binary | openssl enc -base64
   ```
3. **Add the new fingerprint** as a backup in your app:
   ```dart
   SecurityBootstrap.addCertificateFingerprint(
     'api.yourdomain.com', 
     'NEW_CERTIFICATE_FINGERPRINT',
     isPrimary: false
   );
   ```
4. **Set the rotation date** for the certificate:
   ```dart
   SecurityBootstrap.addCertificateFingerprint(
     'api.yourdomain.com', 
     'CURRENT_CERTIFICATE_FINGERPRINT',
     isPrimary: true,
     rotationDate: '2024-12-31' // Date when the new certificate will be activated
   );
   ```
5. **Release an app update** with both the current and new certificate fingerprints

### 2. Certificate Deployment

1. **Deploy the new certificate** to your server on the planned rotation date
2. **Verify the deployment** by checking that the new certificate is being served

### 3. Post-Rotation Update

1. **Update your app code** to make the new certificate the primary one:
   ```dart
   SecurityBootstrap.addCertificateFingerprint(
     'api.yourdomain.com', 
     'NEW_CERTIFICATE_FINGERPRINT',
     isPrimary: true,
     rotationDate: 'NEXT_ROTATION_DATE' // Date for the next rotation
   );
   ```
2. **Add the next backup certificate** if available
3. **Release another app update** with the updated certificate configuration

## Monitoring Certificate Rotation

You can use the built-in methods to check if a certificate rotation is due soon:

```dart
if (SecurityBootstrap.isCertificateRotationDueSoon('api.yourdomain.com')) {
  // Show a warning to the development team
  print('Certificate rotation is due soon for api.yourdomain.com');
  print('Rotation date: ${SecurityBootstrap.getCertificateRotationDate('api.yourdomain.com')}');
}
```

## Emergency Certificate Rotation

If you need to perform an emergency certificate rotation (e.g., due to a security incident):

1. **Deploy the new certificate** to your server immediately
2. **Release an app update** with the new certificate fingerprint as soon as possible
3. **Consider implementing a backup validation mechanism** for critical situations

## Best Practices

1. **Always keep at least one backup fingerprint** in your app
2. **Release updates at least 2 weeks before certificate rotation** to ensure wide distribution
3. **Monitor certificate expiration dates** and set reminders for rotation
4. **Test certificate rotation** in a staging environment before production
5. **Implement analytics** to track certificate validation failures
6. **Consider a fallback mechanism** for emergency situations

## Testing Certificate Rotation

Use the `test_scripts/ci_certificate_pinning_test.sh` script to verify your certificate pinning configuration:

```bash
./test_scripts/ci_certificate_pinning_test.sh
```

This script will check if your app's pinned certificates match the expected certificates.