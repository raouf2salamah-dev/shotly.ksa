import '../security/secure_storage.dart';

/// Repository for managing authentication tokens
/// Provides methods to read, write, and manage access and refresh tokens
class TokenRepository {
  /// Read the current access token
  Future<String?> readAccessToken() async {
    return await SecureStorage.getAccessToken();
  }
  
  /// Read the current refresh token
  Future<String?> readRefreshToken() async {
    return await SecureStorage.getRefreshToken();
  }
  
  /// Save both access and refresh tokens
  Future<void> saveTokens({required String access, required String refresh}) async {
    await SecureStorage.storeAuthTokens(access, refresh);
  }
  
  /// Save only the access token
  Future<void> saveAccessToken(String token) async {
    final refresh = await readRefreshToken();
    if (refresh != null) {
      await saveTokens(access: token, refresh: refresh);
    } else {
      // If no refresh token exists, just save the access token
      await SecureStorage.write('access_token', token);
    }
  }
  
  /// Save only the refresh token
  Future<void> saveRefreshToken(String token) async {
    final access = await readAccessToken();
    if (access != null) {
      await saveTokens(access: access, refresh: token);
    } else {
      // If no access token exists, just save the refresh token
      await SecureStorage.write('refresh_token', token);
    }
  }
  
  /// Clear all authentication tokens
  Future<void> clearTokens() async {
    await SecureStorage.clearAuthTokens();
  }
}