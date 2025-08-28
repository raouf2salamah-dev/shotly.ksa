# Certificate Rotation Procedures

## Overview

This document outlines the procedures for rotating SSL/TLS certificates in our mobile application. Certificate rotation is a critical security practice that ensures we maintain secure connections while minimizing disruption to users. Our approach uses certificate pinning with backup certificates to allow for smooth transitions during certificate renewals.

## Certificate Rotation Workflow

### 1. Preparation Phase

#### 1.1 Schedule Planning

- Schedule certificate rotation at least 30 days before the current certificate expires
- Create a rotation plan in the project management system with specific dates for each phase
- Notify all relevant teams (Security, DevOps, Mobile Development, QA) about the upcoming rotation

#### 1.2 Pre-Rotation Checks

- Verify that the current certificate fingerprints in the app match the live certificates
- Ensure backup certificate storage systems (HashiCorp Vault or AWS Secrets Manager) are accessible
- Confirm CI/CD pipeline scripts for certificate rotation are up-to-date
- Verify that rollback mechanisms are functioning correctly

### 2. Certificate Generation

#### 2.1 Generate New Certificate

- Generate a new certificate for the domain(s) using your Certificate Authority (CA)
- Follow organizational security policies for key generation and storage
- Recommended key parameters:
  - RSA: 2048 bits minimum (4096 bits recommended)
  - ECDSA: P-256 curve minimum (P-384 recommended)
  - Validity period: 1 year maximum (shorter periods are more secure)

#### 2.2 Certificate Verification

- Verify the new certificate's validity period, domain names, and CA chain
- Confirm the certificate meets security requirements (key size, algorithms, etc.)
- Generate SHA-256 fingerprints for the new certificate

### 3. Update Certificate Fingerprints

#### 3.1 Run CI/CD Pipeline Script

```bash
# From the project root directory
cd test_scripts
./ci_certificate_rotation.sh
```

This script will:
- Create a backup of the current fingerprints file
- Retrieve the new certificate fingerprints
- Update the fingerprints file with the new primary fingerprint
- Move the current primary fingerprint to the backup list
- Update the rotation date

#### 3.2 Verify Fingerprint Updates

- Confirm that the fingerprints file has been updated correctly
- Verify that the previous primary fingerprint is now in the backup list
- Check that the rotation date has been updated

### 4. Testing

#### 4.1 Local Testing

- Build the app with the updated fingerprints
- Test connections to all API endpoints using both the new and old certificates
- Run the certificate rotation test script:

```bash
cd test_scripts
./test_certificate_rotation.sh
```

#### 4.2 QA Testing

- Deploy the app to the QA environment
- Perform comprehensive testing of all network-dependent features
- Verify that the app works with both the new and old certificates
- Test certificate transparency log checking:

```bash
cd test_scripts
./ci_ct_log_check.sh
```

### 5. Deployment

#### 5.1 Prepare for Gradual Rollout

- Create a new app release with the updated certificate fingerprints
- Configure the gradual rollout settings:

```bash
cd test_scripts
./gradual_rollout.sh -a start
```

#### 5.2 Deploy to App Stores

- Submit the new app version to the Apple App Store and Google Play Store
- Enable phased rollout features in both app stores
- Monitor the initial rollout phase (10% of users)

#### 5.3 Monitor and Advance Rollout

- Monitor error rates and user feedback during the initial rollout phase
- If no issues are detected, advance to the next rollout phase:

```bash
cd test_scripts
./gradual_rollout.sh -a advance
```

- Continue monitoring and advancing through phases until 100% deployment

### 6. Certificate Deployment

#### 6.1 Deploy New Certificate

- After the app with new fingerprints has reached a significant percentage of users (≥50%), deploy the new certificate to production servers
- Keep the old certificate active during the transition period

#### 6.2 Complete Rollout

- Once the app rollout reaches 100%, continue monitoring for any certificate-related issues
- After a stable period (recommended: 2 weeks), the old certificate can be considered for retirement

### 7. Post-Rotation Tasks

#### 7.1 Update Documentation

- Update certificate inventory with new certificate details
- Document the rotation process, including any issues encountered and their resolutions
- Update the certificate rotation schedule for the next rotation

#### 7.2 Backup Certificate Management

- Update certificate fingerprints in backup storage systems:

```bash
cd test_scripts
./backup_cert_vault.sh store primary api.example.com <new-fingerprint>
```

Or for AWS Secrets Manager:

```bash
cd test_scripts
python aws_secrets_manager.py store api.example.com primary <new-fingerprint>
```

## Emergency Procedures

### Certificate Compromise

If a certificate is compromised or needs to be revoked immediately:

1. Generate a new certificate with different keys
2. Update the fingerprints file with the new certificate fingerprint
3. Deploy an emergency app update with the new fingerprints
4. Request expedited review from app stores for the emergency update
5. Revoke the compromised certificate
6. Notify users about the security update

### Rollback Procedure

If issues are detected during the rollout:

1. Assess the severity and impact of the issues
2. If necessary, trigger a rollback:

```bash
cd test_scripts
./gradual_rollout.sh -a rollback -r "Reason for rollback"
```

Or manually:

```bash
cd test_scripts
./cert_rollback.sh
```

3. Halt the app rollout in the app stores
4. Investigate and resolve the issues before attempting another rotation

## Quarterly Audit

A quarterly audit of certificate fingerprints should be performed to ensure that the app's pinned certificates match the live certificates:

```bash
cd test_scripts
./quarterly_cert_audit.sh
```

This script will:
- Verify that the pinned fingerprints match the live certificates
- Check certificate expiration dates
- Verify rotation dates
- Generate an audit report

## Roles and Responsibilities

| Role | Responsibilities |
|------|------------------|
| Security Team | Certificate generation, security review, approval of rotation plan |
| Mobile Development | Implementation of fingerprint updates, testing with new certificates |
| DevOps | Certificate deployment, CI/CD pipeline management |
| QA | Testing of app with new certificates, verification of rotation success |
| Release Management | App store submission, phased rollout management |

## Timeline

A typical certificate rotation should follow this timeline:

| Time | Action |
|------|--------|
| T-30 days | Begin planning for certificate rotation |
| T-25 days | Generate new certificate |
| T-20 days | Update fingerprints in development and test environments |
| T-15 days | Complete QA testing |
| T-10 days | Submit app update to app stores |
| T-5 days | Begin phased rollout (10%) |
| T-3 days | Advance to 50% rollout if no issues |
| T-1 day | Advance to 100% rollout if no issues |
| T-day | Deploy new certificate to production servers |
| T+14 days | Consider retiring old certificate |

## Troubleshooting

### Common Issues

#### Certificate Pinning Failures

**Symptoms**: App unable to connect to API, SSL handshake failures

**Resolution**:
- Verify that the correct fingerprints are in the app
- Check that both primary and backup fingerprints are properly configured
- Ensure the server is using the expected certificate

#### App Store Rejection

**Symptoms**: App update rejected by app store review

**Resolution**:
- Ensure the app functions properly with the new certificate
- Verify that all network connections work correctly
- Check for any security warnings or errors in the app

#### Gradual Rollout Issues

**Symptoms**: Increased error rates during rollout

**Resolution**:
- Use the rollback script to revert to the previous fingerprints
- Investigate the cause of the errors
- Fix issues and restart the rollout process

## References

- [OWASP Certificate and Public Key Pinning](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
- [Android Network Security Configuration](https://developer.android.com/training/articles/security-config)
- [iOS App Transport Security](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)

## Appendix

### Certificate Fingerprint Generation

To generate a SHA-256 fingerprint for a certificate:

```bash
openssl x509 -in certificate.pem -noout -fingerprint -sha256 | sed 's/SHA256 Fingerprint=//g' | sed 's/://g'
```

### Certificate Transparency Log Checking

To check if a certificate appears in Certificate Transparency logs:

```bash
cd test_scripts
./ci_ct_log_check.sh -d api.example.com -m 2
```

This verifies that the certificate appears in at least 2 different CT logs.