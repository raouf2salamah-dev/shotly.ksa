# SSL Certificate Tracking

This document tracks the SSL certificate expiration dates for all domains used in our application. Certificate pinning is implemented through the `CertificatePinningService` class.

## Certificate Expiration Dates

| Domain | Expiration Date | Fingerprint (SHA-256) | Renewal Reminder |
|--------|----------------|------------------------|------------------|
| api.yourdomain.com | February 7, 2026 | AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D | January 7, 2026 |
| cicd.yourdomain.com | February 7, 2026 | AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D | January 7, 2026 |
| security.yourdomain.com | February 7, 2026 | AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D | January 7, 2026 |
| api.example.com | N/A (Could not connect) | AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D | N/A |

## Certificate Rotation Schedule

The certificate rotation schedule is defined in the `CertificatePinningService` class. Current rotation dates:

```
'api.yourdomain.com': '2026-01-07'   // 30 days before expiration
'api.example.com': '2026-01-07'      // 30 days before expiration
'cicd.yourdomain.com': '2026-01-07'  // 30 days before expiration
'security.yourdomain.com': '2026-01-07' // 30 days before expiration
```

## Certificate Renewal Process

1. Generate new certificates 30 days before expiration
2. Add new certificate fingerprints as backup in `CertificatePinningService`
3. Deploy the updated app with both old and new fingerprints
4. Once the new certificates are active, move the new fingerprint to primary and remove the old one
5. Update this tracking document with new expiration dates

## Calendar Reminders

- Set calendar reminder for January 7, 2026 (30 days before expiration)
- Set calendar reminder for December 8, 2025 (30 days before rotation date)

## Notes

- All domains currently use the same certificate expiring on February 7, 2026
- Certificate pinning is implemented through the centralized `CertificatePinningService`
- Backup fingerprints are configured for certificate rotation