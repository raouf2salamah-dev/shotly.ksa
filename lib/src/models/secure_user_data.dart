import '../services/secure_storage_service.dart';
import '../services/encrypted_hive_service.dart';
import 'dart:convert';

/// SecureUserData demonstrates a best practice approach for storing user data
/// by combining flutter_secure_storage (for sensitive data) and encrypted Hive (for larger data)
class SecureUserData {
  // Services
  final EncryptedHiveService _encryptedHive = EncryptedHiveService();
  
  // Storage keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userProfileKey = 'user_profile';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _userActivityKey = 'user_activity';
  
  // Initialize services
  Future<void> init() async {
    // Initialize encrypted Hive if not already initialized
    if (!_encryptedHive.isInitialized) {
      await _encryptedHive.init();
    }
  }
  
  // AUTHENTICATION DATA (highly sensitive, small size - use secure storage)
  
  /// Store authentication token
  Future<void> saveAuthToken(String token) async {
    await SecureStorageService.write(_authTokenKey, token);
  }
  
  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await SecureStorageService.read(_authTokenKey);
  }
  
  /// Store refresh token
  Future<void> saveRefreshToken(String token) async {
    await SecureStorageService.write(_refreshTokenKey, token);
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await SecureStorageService.read(_refreshTokenKey);
  }
  
  /// Store user ID
  Future<void> saveUserId(String userId) async {
    await SecureStorageService.write(_userIdKey, userId);
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    return await SecureStorageService.read(_userIdKey);
  }
  
  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await SecureStorageService.delete(_authTokenKey);
    await SecureStorageService.delete(_refreshTokenKey);
    // Don't delete user ID as it might be needed for other operations
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
  
  // USER PROFILE (moderately sensitive, larger size - use encrypted Hive)
  
  /// Save user profile
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _encryptedHive.saveData(_userProfileKey, profile);
  }
  
  /// Get user profile
  Map<String, dynamic>? getUserProfile() {
    final profile = _encryptedHive.getData(_userProfileKey);
    if (profile == null) return null;
    return Map<String, dynamic>.from(profile);
  }
  
  // USER PREFERENCES (less sensitive, structured data - use encrypted Hive)
  
  /// Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    await _encryptedHive.saveData(_userPreferencesKey, preferences);
  }
  
  /// Get user preferences
  Map<String, dynamic>? getUserPreferences() {
    final preferences = _encryptedHive.getData(_userPreferencesKey);
    if (preferences == null) return null;
    return Map<String, dynamic>.from(preferences);
  }
  
  /// Update specific preference
  Future<void> updatePreference(String key, dynamic value) async {
    final preferences = getUserPreferences() ?? {};
    preferences[key] = value;
    await saveUserPreferences(preferences);
  }
  
  // USER ACTIVITY (not sensitive, large dataset - use encrypted Hive)
  
  /// Add activity to user history
  Future<void> addUserActivity(Map<String, dynamic> activity) async {
    final activities = getUserActivities() ?? [];
    activities.add({
      ...activity,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Limit the number of stored activities (e.g., keep only the last 100)
    if (activities.length > 100) {
      activities.removeRange(0, activities.length - 100);
    }
    
    await _encryptedHive.saveData(_userActivityKey, activities);
  }
  
  /// Get user activities
  List<Map<String, dynamic>>? getUserActivities() {
    final activities = _encryptedHive.getData(_userActivityKey);
    if (activities == null) return null;
    return List<Map<String, dynamic>>.from(activities);
  }
  
  /// Clear user activities
  Future<void> clearUserActivities() async {
    await _encryptedHive.deleteData(_userActivityKey);
  }
  
  // COMPLETE USER DATA MANAGEMENT
  
  /// Export all user data (for GDPR compliance)
  Future<String> exportUserData() async {
    final Map<String, dynamic> userData = {};
    
    // Get user ID
    final userId = await getUserId();
    if (userId != null) {
      userData['user_id'] = userId;
    }
    
    // Get profile
    final profile = getUserProfile();
    if (profile != null) {
      userData['profile'] = profile;
    }
    
    // Get preferences
    final preferences = getUserPreferences();
    if (preferences != null) {
      userData['preferences'] = preferences;
    }
    
    // Get activities
    final activities = getUserActivities();
    if (activities != null) {
      userData['activities'] = activities;
    }
    
    // Convert to JSON string
    return json.encode(userData);
  }
  
  /// Clear all user data (for account deletion)
  Future<void> clearAllUserData() async {
    // Clear auth data from secure storage
    await clearAuthData();
    await SecureStorageService.delete(_userIdKey);
    
    // Clear data from encrypted Hive
    await _encryptedHive.deleteData(_userProfileKey);
    await _encryptedHive.deleteData(_userPreferencesKey);
    await _encryptedHive.deleteData(_userActivityKey);
  }
}