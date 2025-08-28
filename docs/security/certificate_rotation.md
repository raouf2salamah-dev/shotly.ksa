# Certificate Rotation Procedures

This document outlines the procedures for rotating SSL certificates used in certificate pinning for our mobile application.

## Overview

Certificate rotation is a critical security practice that involves replacing SSL certificates before they expire or if they become compromised. For our mobile application that implements certificate pinning, this process requires careful planning to avoid service disruption.

## Certificate Rotation Schedule

- **Regular Rotation**: Every 12 months
- **Emergency Rotation**: Immediately upon suspicion of compromise
- **Preparation**: Begin process 60 days before expiration

## Pre-Rotation Checklist

1. Verify current certificate expiration dates
2. Generate new certificates with appropriate validity periods
3. Extract public key fingerprints using the OpenSSL command:
   ```bash
   openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
   ```
4. Prepare updated configuration files for both platforms:
   - iOS: `Info.plist` with updated certificate hashes
   - Android: `network_security_config.xml` with updated certificate hashes

## Rotation Process

### 1. Preparation Phase

1. Generate new certificates for all required domains
2. Install new certificates on staging servers first
3. Update the mobile app with both old and new certificate fingerprints
4. Release a new app version that supports both certificates
5. Monitor adoption rate until it reaches at least 80%

### 2. Transition Phase

1. Install new certificates on production servers
2. Keep both old and new certificates active during transition
3. Monitor for any certificate-related errors or issues

### 3. Completion Phase

1. After sufficient adoption period (minimum 60 days):
   - Release a new app version that only includes the new certificate fingerprints
   - Remove old certificates from pinning configuration

## Emergency Certificate Rotation

In case of certificate compromise:

1. Generate new certificates immediately
2. Push an emergency app update with both old and new certificate fingerprints
3. Install new certificates on all servers
4. Expedite the transition period based on app update adoption
5. Consider server-side mechanisms to force app updates if necessary

## Rollback Procedure

If issues are detected during certificate rotation:

1. Revert server certificates to previous version
2. If necessary, release an emergency app update reverting to previous certificate fingerprints
3. Document the issue and solution for future reference

## Documentation Requirements

For each certificate rotation, document:

1. Date of rotation
2. Reason for rotation (regular schedule or emergency)
3. Certificate details (issuer, validity period, fingerprints)
4. Any issues encountered and their resolutions
5. Adoption metrics for app versions supporting new certificates

## Responsible Teams

- **Security Team**: Certificate generation and verification
- **DevOps**: Server certificate installation
- **Mobile Development**: App updates with new certificate fingerprints
- **QA**: Testing certificate pinning functionality