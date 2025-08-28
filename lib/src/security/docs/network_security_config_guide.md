# Android Network Security Configuration Guide

## Overview

This guide explains how we've implemented Android's Network Security Configuration to enhance the security of network communications in our app. This feature allows us to:

1. Restrict cleartext (HTTP) traffic
2. Specify trusted certificate authorities
3. Implement certificate pinning
4. Configure domain-specific security settings

## Implementation Details

We've implemented the following security measures:

### 1. Restricted Cleartext Traffic

All cleartext (HTTP) traffic is disabled by default, forcing the app to use secure HTTPS connections for all network communications. This is implemented through:

- Setting `android:usesCleartextTraffic="false"` in the manifest (legacy approach)
- Using a network security configuration file with `cleartextTrafficPermitted="false"` (modern approach)

### 2. Network Security Configuration File

The configuration is defined in `android/app/src/main/res/xml/network_security_config.xml` with the following settings:

```xml
<network-security-config>
    <!-- Base configuration that restricts cleartext traffic -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <!-- Trust the system certificates -->
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

### 3. Manifest Configuration

The AndroidManifest.xml references the network security configuration:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ... >
```

## Advanced Configuration Options

### Certificate Pinning

For additional security, we can implement certificate pinning by uncommenting and configuring the domain-specific section in the network security configuration file:

```xml
<domain-config>
    <domain includeSubdomains="true">example.com</domain>
    <pin-set>
        <pin digest="SHA-256">YourBase64EncodedPinHere</pin>
        <pin digest="SHA-256">YourBackupBase64EncodedPinHere</pin>
    </pin-set>
</domain-config>
```

To generate certificate pins:

1. Extract the certificate from your server: 
   ```
   openssl s_client -servername example.com -connect example.com:443 < /dev/null | openssl x509 -outform DER > cert.der
   ```

2. Generate the pin hash:
   ```
   openssl x509 -inform DER -in cert.der -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
   ```

### Domain-Specific Exceptions

If specific domains need to allow cleartext traffic (e.g., for development or legacy systems), you can configure exceptions:

```xml
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="false">localhost</domain>
</domain-config>
```

## Security Considerations

- Always include backup pins when implementing certificate pinning to avoid app breakage if the primary certificate changes
- Test thoroughly after implementing these security measures to ensure all network communications work as expected
- Consider implementing a fallback mechanism for development/testing environments

## References

- [Android Network Security Configuration Documentation](https://developer.android.com/training/articles/security-config)
- [Certificate Pinning Best Practices](https://developer.android.com/training/articles/security-ssl#Pinning)