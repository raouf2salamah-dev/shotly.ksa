# Auth Interceptor Guide

## Overview
The `AuthInterceptor` is a Dio HTTP client interceptor that provides automatic token management for API requests. It handles adding authentication tokens to requests, refreshing expired tokens, and securely storing tokens using the `SecureStorageService`.

## Features

- **Automatic Token Injection**: Adds access tokens to request headers
- **Token Refresh**: Automatically refreshes expired tokens when receiving 401 responses
- **Secure Storage**: Uses platform-specific secure storage for tokens
- **Request Retry**: Automatically retries failed requests after token refresh

## Implementation

### 1. Setup Dio with AuthInterceptor

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
));

// Add the AuthInterceptor
dio.interceptors.add(AuthInterceptor(dio));
```

### 2. Making Authenticated Requests

```dart
// The interceptor automatically adds the token
try {
  final response = await dio.get('/protected-resource');
  // Handle successful response
} catch (e) {
  // Handle errors
  if (e is DioError && e.response?.statusCode == 401) {
    // Authentication failed even after refresh attempt
    // Handle by redirecting to login
  }
}
```

### 3. Token Management

Tokens are stored using `SecureStorageService` with these keys:

- `access_token`: Short-lived token (typically 15 minutes)
- `refresh_token`: Longer-lived token (typically 7 days)

```dart
// Manually store tokens (e.g., after login)
await SecureStorageService.write('access_token', accessToken);
await SecureStorageService.write('refresh_token', refreshToken);

// Clear tokens (e.g., during logout)
await SecureStorageService.delete('access_token');
await SecureStorageService.delete('refresh_token');
```

## How Token Refresh Works

1. When a request receives a 401 Unauthorized response, the interceptor attempts to refresh the token
2. It uses the stored refresh token to request a new access token from the server
3. If successful, it updates both tokens in secure storage
4. It then retries the original request with the new access token
5. If refresh fails, the original error is passed through

## Security Considerations

- **Token Storage**: Tokens are stored using platform-specific secure storage (iOS Keychain, Android EncryptedSharedPreferences)
- **Refresh Lock**: A lock mechanism prevents multiple simultaneous refresh attempts
- **Error Handling**: Failed refreshes are properly handled to prevent infinite loops

## Example Implementation

See the `AuthInterceptorExample` screen for a complete demonstration of using the `AuthInterceptor` with Dio, including:

- Storing and retrieving tokens
- Making authenticated requests
- Handling token refresh
- Error handling

Access this example at the route: `/auth-interceptor-example`