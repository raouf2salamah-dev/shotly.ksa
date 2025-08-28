# Certificate Management Policy

## Overview

This policy document outlines the procedures and requirements for managing SSL/TLS certificate fingerprints (pins) in our mobile application. It covers the processes for adding, updating, and rotating certificate pins, as well as testing procedures and compliance requirements.

## Certificate Pinning Strategy

Our application uses certificate pinning to enhance security by validating server certificates against known, trusted fingerprints. The strategy includes:

1. **Primary and Backup Fingerprints**: Each domain has both primary and backup fingerprints to support certificate rotation
2. **Automated Rotation**: CI/CD pipeline scripts automate the fingerprint update process
3. **Gradual Rollout**: Certificate updates are deployed gradually to minimize user impact
4. **Regular Audits**: Quarterly audits verify the integrity of pinned certificates

## Adding or Updating Certificate Pins

### Prerequisites

Before adding or updating certificate pins, ensure you have:

- Access to the certificate or the server hosting it
- Appropriate permissions to modify the application code
- Knowledge of the certificate's validity period and renewal schedule

### Process for Adding New Pins

1. **Generate Certificate Fingerprint**

   Use OpenSSL to generate the SHA-256 fingerprint of the certificate:

   ```bash
   openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | \
   openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | \
   openssl dgst -sha256 -binary | openssl enc -base64
   ```

   Or for colon-separated format:

   ```bash
   openssl x509 -in certificate.pem -noout -fingerprint -sha256
   ```

2. **Update Certificate Fingerprints File**

   Add the new fingerprint to the `_certificateFingerprints` map in `CertificatePinningService`:

   ```dart
   Map<String, Map<String, List<String>>> _certificateFingerprints = {
     'new.domain.com': {
       'primary': [
         'NEW:CERTIFICATE:FINGERPRINT:HASH:VALUE',
       ],
       'backup': [
         'BACKUP:CERTIFICATE:FINGERPRINT:HASH:VALUE',
       ]
     },
     // Existing domains...
   };
   ```

3. **Update Certificate Rotation Dates**

   Add the domain to the `_certificateRotationDates` map with the current date:

   ```dart
   Map<String, String> _certificateRotationDates = {
     'new.domain.com': '2025-08-16',
     // Existing domains...
   };
   ```

4. **Test the New Fingerprint**

   Run the certificate pinning test script to verify the new fingerprint:

   ```bash
   cd test_scripts
   ./ci_certificate_pinning_test.sh -d new.domain.com
   ```

5. **Document the New Fingerprint**

   Update the certificate inventory with the new fingerprint details:
   - Domain name
   - Certificate issuer
   - Validity period
   - Fingerprint value
   - Date added

## Certificate Rotation Process

Certificate rotation should be performed regularly, ideally at least 30 days before the current certificate expires.

### Automated Rotation Process

1. **Run the Certificate Rotation Script**

   ```bash
   cd test_scripts
   ./ci_certificate_rotation.sh -d api.yourdomain.com
   ```

   This script will:
   - Create a backup of the current fingerprints
   - Retrieve the new certificate fingerprint
   - Update the fingerprints file with the new primary fingerprint
   - Move the current primary fingerprint to the backup list
   - Update the rotation date

2. **Verify the Rotation**

   ```bash
   cd test_scripts
   ./ci_certificate_pinning_test.sh -d api.yourdomain.com
   ```

3. **Commit and Push Changes**

   Commit the updated fingerprints file to the repository and push the changes to trigger the CI/CD pipeline.

### Manual Rotation Process

If automated rotation is not possible, follow these steps:

1. **Generate the New Certificate Fingerprint** (as described above)

2. **Update the Fingerprints File**
   - Move the current primary fingerprint to the backup list
   - Add the new fingerprint as the primary
   - Update the rotation date

3. **Test the Updated Fingerprints**

4. **Commit and Push Changes**

### Gradual Rollout

To minimize the impact of certificate changes, use the gradual rollout process:

1. **Start the Rollout**

   ```bash
   cd test_scripts
   ./gradual_rollout.sh -a start
   ```

2. **Monitor and Advance**

   Monitor error rates and user feedback during each phase of the rollout. If no issues are detected, advance to the next phase:

   ```bash
   ./gradual_rollout.sh -a advance
   ```

3. **Complete the Rollout**

   Once the app with new fingerprints has reached 100% of users, deploy the new certificate to production servers.

### Emergency Rotation

In case of certificate compromise or other security incidents:

1. **Generate a new certificate** with different keys
2. **Update the fingerprints** using the emergency update process
3. **Deploy an emergency app update** with the new fingerprints
4. **Request expedited review** from app stores
5. **Revoke the compromised certificate**

## Testing Checklist

Before deploying certificate changes to production, complete the following tests:

### Local Testing

- [ ] Build the app with updated fingerprints
- [ ] Verify connections to all API endpoints using the new certificate
- [ ] Verify connections to all API endpoints using the backup certificate
- [ ] Test certificate validation failure scenarios
- [ ] Verify graceful degradation for non-critical APIs
- [ ] Test developer mode bypass functionality (in development builds only)

### CI/CD Pipeline Testing

- [ ] Run automated certificate pinning tests
   ```bash
   ./ci_certificate_pinning_test.sh
   ```
- [ ] Verify certificate transparency log checking
   ```bash
   ./ci_ct_log_check.sh -d api.yourdomain.com -m 2
   ```
- [ ] Run the quarterly audit script to verify all certificates
   ```bash
   ./quarterly_cert_audit.sh
   ```

### QA Testing

- [ ] Deploy to QA environment
- [ ] Test all network-dependent features
- [ ] Verify error messages for certificate validation failures
- [ ] Test with both primary and backup certificates
- [ ] Verify cached data is shown for non-critical APIs when certificate validation fails

## Rollback Procedure

If issues are detected during the rollout:

1. **Trigger a Rollback**

   ```bash
   cd test_scripts
   ./gradual_rollout.sh -a rollback -r "Reason for rollback"
   ```

   Or manually:

   ```bash
   ./cert_rollback.sh
   ```

2. **Halt the App Rollout** in the app stores
3. **Investigate and Resolve** the issues before attempting another rotation

## Audit and Compliance

### Quarterly Audit

Perform a quarterly audit of certificate fingerprints to ensure compliance and security:

```bash
cd test_scripts
./quarterly_cert_audit.sh
```

The audit should verify:
- Pinned fingerprints match live certificates
- Certificates are not expired or near expiration
- Rotation dates are documented
- Backup fingerprints are available

### Compliance Requirements

Our certificate management process is designed to meet the following security standards:

#### OWASP MASVS (Mobile Application Security Verification Standard)

- **V5.4**: "The app either uses its own certificate store, or pins the endpoint certificate or public key, and does not establish connections with endpoints that offer a different certificate or key, even if signed by a trusted CA."

- **V5.5**: "The app doesn't rely on a single insecure communication channel (email or SMS) for critical operations, such as enrollments and account recovery."

- **V5.6**: "The app only depends on up-to-date connectivity and security libraries."

#### PCI DSS (Payment Card Industry Data Security Standard)

If the application processes payment information, it must comply with PCI DSS requirements:

- **Requirement 4.1**: "Use strong cryptography and security protocols to safeguard sensitive cardholder data during transmission over open, public networks."

- **Requirement 6.5.4**: "Implement proper error handling."

- **Requirement 6.6**: "For public-facing web applications, address new threats and vulnerabilities on an ongoing basis."

### Documentation Requirements

Maintain the following documentation for compliance purposes:

- Certificate inventory with fingerprints and expiration dates
- Certificate rotation history
- Quarterly audit reports
- Incident reports for any certificate-related security events
- Test results from certificate pinning validation

## Roles and Responsibilities

| Role | Responsibilities |
|------|------------------|
| Security Team | Certificate generation, security review, approval of rotation plan |
| Mobile Development | Implementation of fingerprint updates, testing with new certificates |
| DevOps | Certificate deployment, CI/CD pipeline management |
| QA | Testing of app with new certificates, verification of rotation success |
| Release Management | App store submission, phased rollout management |

## References

- [OWASP Certificate and Public Key Pinning](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
- [OWASP MASVS](https://github.com/OWASP/owasp-masvs)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
- [Android Network Security Configuration](https://developer.android.com/training/articles/security-config)
- [iOS App Transport Security](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)