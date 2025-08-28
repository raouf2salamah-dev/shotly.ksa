# Security Testing Scripts

This directory contains scripts for testing various security aspects of the application, including HMAC-SHA256 request signing implementation, certificate pinning, secure storage, auth token refresh, and regression testing. These scripts help verify that security implementations are working correctly and haven't broken core functionality.

## Scripts Overview

### Comprehensive Security Test Scripts

#### 1. `run_all_security_tests.sh`

Master script that runs all security tests in sequence and generates a comprehensive summary.

**Usage:**
```bash
./run_all_security_tests.sh
```

#### 2. `certificate_pinning_test.sh`

Verifies that the app rejects connections when a MITM attack is attempted using mitmproxy.

**Usage:**
```bash
./certificate_pinning_test.sh
```

#### 3. `secure_storage_test.sh`

Ensures tokens exist and are not readable in plain text from the device file system.

**Usage:**
```bash
./secure_storage_test.sh
```

#### 4. `auth_refresh_test.sh`

Tests token expiry and refresh flows to ensure proper handling of expired tokens.

**Usage:**
```bash
./auth_refresh_test.sh
```

#### 5. `request_signing_test.sh`

Verifies that the server rejects requests with wrong signature/timestamp.

**Usage:**
```bash
./screen_capture_protection_test.sh
```

#### 6. `biometric_auth_test.sh`

Tests biometric authentication and timeout functionality.

**Usage:**
```bash
./biometric_auth_test.sh
```

#### 7. `screen_capture_protection_test.sh`

Tests screenshot prevention and screen recording protection.

**Usage:**
```bash
./request_signing_test.sh
```

#### 8. `regression_test.sh`

Runs main app flows (login, upload, favorites) after adding security features to ensure functionality is preserved.

**Usage:**
```bash
./regression_test.sh
```

### API Testing Scripts

#### 1. `simulate_expired_token.dart`

This script simulates an expired token scenario to test the token refresh mechanism. It creates a mock server that:

1. Returns 401 on the first request with a valid token (simulating expiration)
2. Allows token refresh
3. Accepts the request with the new token

**Usage:**
```bash
dart simulate_expired_token.dart
```

#### 2. `simulate_request_tampering.dart`

This script simulates request tampering scenarios to test signature validation. It creates a mock server that validates HMAC-SHA256 signatures and tests:

1. Valid signature (should succeed)
2. Tampered path (should fail)
3. Tampered body (should fail)
4. Tampered timestamp (should fail)
5. Missing signature (should fail)

**Usage:**
```bash
dart simulate_request_tampering.dart
```

#### 3. `curl_test_commands.sh`

This script contains curl commands to test the signed API endpoints against a real server. It demonstrates both valid and invalid signature scenarios:

1. Valid request
2. Tampered path
3. Tampered body
4. Expired timestamp
5. Replay attack (reusing a valid signature)
6. Missing signature

**Usage:**
```bash
chmod +x curl_test_commands.sh
./curl_test_commands.sh
```

## Prerequisites

- Android or iOS device connected for UI tests
- mitmproxy installed for certificate pinning tests
- Dart SDK for running the Dart scripts
- Bash shell for running the scripts
- `curl` and `jq` installed for API tests
- OpenSSL for signature generation
- adb (Android) or idevice tools (iOS) for device interaction

## Configuration

Before running the scripts, you may need to modify them to match your environment:

- In all scripts, update the `APP_PACKAGE` variable to match your application package name
- In API test scripts, update the `API_BASE_URL`, `TEST_USERNAME`, and `TEST_PASSWORD` variables
- For request signing tests, update the `API_KEY` and `API_SECRET` variables
- In `curl_test_commands.sh`, update the `API_URL`, `ENDPOINT`, `DEVICE_ID`, and `SIGNING_KEY` variables
- The Dart scripts use localhost with predefined ports (8080 and 8081)

## Security Considerations

These scripts are designed for testing purposes only and should not be used in production environments. The signing keys used in these scripts are for demonstration purposes and should be replaced with secure, randomly generated keys in a real application.

## Expected Results

### For Security Test Scripts:

#### Certificate Pinning Test:
- The app should reject connections when a MITM attack is attempted
- Certificate validation errors should be logged

#### Secure Storage Test:
- Tokens should exist in the app's storage
- Tokens should not be stored in plain text

#### Auth Token Refresh Test:
- The app should properly handle expired tokens
- Token refresh should succeed
- New tokens should work correctly

#### Request Signing Test:
- Valid signatures should be accepted
- Invalid signatures should be rejected
- Incorrect timestamps should be rejected

#### Regression Test:
- All main app flows should work correctly after security implementations

### For API Testing Scripts:

#### For `simulate_expired_token.dart`:
- The first request should fail with a 401 error
- The token refresh should succeed
- The retried request with the new token should succeed

#### For `simulate_request_tampering.dart`:
- The valid request should succeed
- All tampered requests should fail with appropriate error messages

#### For `curl_test_commands.sh`:
- The valid request should return a 200 OK response
- All invalid requests should return a 401 Unauthorized response