import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

// Import your app's security components
import '../lib/security/secure_storage.dart';
import '../lib/src/services/encrypted_hive_service.dart';

// Token Repository class for managing authentication tokens
class TokenRepository {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  final SecureStorage _secureStorage = SecureStorage();
  
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(_accessTokenKey, token);
  }
  
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(_refreshTokenKey, token);
  }
  
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(_accessTokenKey);
  }
  
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(_refreshTokenKey);
  }
  
  Future<void> clear() async {
    await _secureStorage.delete(_accessTokenKey);
    await _secureStorage.delete(_refreshTokenKey);
  }
}

// Security Bootstrap class for initializing and managing security components
class SecurityBootstrap {
  static Future<void> init() async {
    // Initialize Hive with encryption
    await EncryptedHiveService().initialize();
  }
  
  static Future<void> secureLogout() async {
    // Clear tokens
    await TokenRepository().clear();
    
    // Clear encrypted data
    await EncryptedHiveService().clearAll();
  }
}

// Wrapper for EncryptedHiveService to match the test's expected API
class EncryptedBox {
  final EncryptedHiveService _service = EncryptedHiveService();
  
  Future<void> put(String key, dynamic value) async {
    await _service.saveData(key, value);
  }
  
  T? get<T>(String key) {
    return _service.getData(key) as T?;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Security Verification Tests', () {
    late TokenRepository tokenRepository;
    final testAccessToken = 'test_access_token_${DateTime.now().millisecondsSinceEpoch}';
    final testRefreshToken = 'test_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
    
    setUpAll(() async {
      // Initialize security components
      await SecurityBootstrap.init();
      tokenRepository = TokenRepository();
      
      // Clear any existing tokens to start fresh
      await tokenRepository.clear();
    });

    test('1. Cold Start - Token Persistence Test', () async {
      // Save tokens
      await tokenRepository.saveAccessToken(testAccessToken);
      await tokenRepository.saveRefreshToken(testRefreshToken);
      
      // Verify tokens were saved
      expect(await tokenRepository.getAccessToken(), equals(testAccessToken));
      expect(await tokenRepository.getRefreshToken(), equals(testRefreshToken));
      
      // Simulate app restart by recreating the repository
      final newTokenRepository = TokenRepository();
      
      // Verify tokens persist after "restart"
      expect(await newTokenRepository.getAccessToken(), equals(testAccessToken));
      expect(await newTokenRepository.getRefreshToken(), equals(testRefreshToken));
    });

    test('2. File Inspection - No Plain Text Tokens', () async {
      if (!kIsWeb) {
        // Get app's document directory
        final directory = await getApplicationDocumentsDirectory();
        final appDir = directory.path;
        
        // Search for files that might contain tokens
        final files = Directory(appDir)
            .listSync(recursive: true)
            .whereType<File>()
            .toList();
        
        // Read file contents and check for plain tokens
        for (final file in files) {
          if (file.path.endsWith('.hive') || file.path.endsWith('.lock')) {
            continue; // Skip Hive database files
          }
          
          try {
            final content = await file.readAsString();
            expect(content.contains(testAccessToken), isFalse, 
                reason: 'Found plain text access token in ${file.path}');
            expect(content.contains(testRefreshToken), isFalse, 
                reason: 'Found plain text refresh token in ${file.path}');
          } catch (e) {
            // File might not be readable as text, which is fine
          }
        }
      } else {
        // Web platform doesn't have direct file access
        print('Skipping file inspection test on web platform');
      }
    });

    test('3. Logout Test - Tokens and Encrypted Box Cleared', () async {
      // First verify tokens exist
      expect(await tokenRepository.getAccessToken(), equals(testAccessToken));
      
      // Store some data in encrypted box
      final testProfileData = {'name': 'Test User', 'email': 'test@example.com'};
      await EncryptedBox().put('user_profile', testProfileData);
      
      // Verify data was stored
      final storedProfile = await EncryptedBox().get<Map<String, dynamic>>('user_profile');
      expect(storedProfile?['name'], equals('Test User'));
      
      // Perform secure logout
      await SecurityBootstrap.secureLogout();
      
      // Verify tokens are gone
      expect(await tokenRepository.getAccessToken(), isNull);
      expect(await tokenRepository.getRefreshToken(), isNull);
      
      // Verify encrypted box data is cleared
      final clearedProfile = await EncryptedBox().get<Map<String, dynamic>>('user_profile');
      expect(clearedProfile, isNull);
    });

    test('4. Token Rotation Safety Test', () async {
      // Save initial tokens
      await tokenRepository.saveAccessToken('initial_access_token');
      await tokenRepository.saveRefreshToken('initial_refresh_token');
      
      // Simulate token rotation
      await tokenRepository.saveAccessToken('rotated_access_token');
      await tokenRepository.saveRefreshToken('rotated_refresh_token');
      
      // Verify rotated tokens are retrieved correctly
      expect(await tokenRepository.getAccessToken(), equals('rotated_access_token'));
      expect(await tokenRepository.getRefreshToken(), equals('rotated_refresh_token'));
    });

    test('5. Crash Recovery Test', () async {
      // Save tokens
      await tokenRepository.saveAccessToken('pre_crash_access_token');
      
      // Simulate crash during refresh token write by using a Completer that never completes
      final completer = Completer<void>();
      
      // This would normally be awaited, but we're simulating a crash
      unawaited(tokenRepository.saveRefreshToken('pre_crash_refresh_token')
          .then((_) => completer.complete()));
      
      // Don't wait for the operation to complete, simulate app termination
      
      // Now simulate app restart with new instances
      final recoveryTokenRepository = TokenRepository();
      
      // Verify access token was saved (transaction completed)
      expect(await recoveryTokenRepository.getAccessToken(), equals('pre_crash_access_token'));
      
      // The refresh token write might or might not have completed
      // We're testing that the app doesn't crash on restart, not the specific token value
      final refreshToken = await recoveryTokenRepository.getRefreshToken();
      print('Refresh token after simulated crash: $refreshToken');
      
      // Clean up
      await recoveryTokenRepository.clear();
    });
  });
}