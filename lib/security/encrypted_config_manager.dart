import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// A class for managing encrypted configuration files
/// 
/// This class provides methods for securely storing and retrieving sensitive
/// configuration data, such as certificate fingerprints, in encrypted files.
class EncryptedConfigManager {
  // Singleton instance
  static final EncryptedConfigManager _instance = EncryptedConfigManager._internal();
  
  // Factory constructor to return the singleton instance
  factory EncryptedConfigManager() {
    return _instance;
  }
  
  // Private constructor
  EncryptedConfigManager._internal();
  
  // Secure storage for encryption keys
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Key for storing the encryption key in secure storage
  static const String _encryptionKeyKey = 'encryption_key';
  
  // Default config file name
  static const String _defaultConfigFileName = 'secure_config.enc';
  
  /// Initialize the encrypted config manager
  /// 
  /// This method ensures that an encryption key is available in secure storage.
  /// If no key exists, a new one is generated and stored.
  Future<void> initialize() async {
    // Check if an encryption key already exists
    final encryptionKey = await _secureStorage.read(key: _encryptionKeyKey);
    
    // If no encryption key exists, generate a new one and store it
    if (encryptionKey == null) {
      // Generate a random 32-byte key
      final key = encrypt.Key.fromSecureRandom(32).base64;
      
      // Store the key in secure storage
      await _secureStorage.write(key: _encryptionKeyKey, value: key);
    }
  }
  
  /// Get the encryption key from secure storage
  /// 
  /// Returns the encryption key as an encrypt.Key object
  Future<encrypt.Key> _getEncryptionKey() async {
    // Read the encryption key from secure storage
    final keyString = await _secureStorage.read(key: _encryptionKeyKey);
    
    // If no key exists, throw an exception
    if (keyString == null) {
      throw Exception('Encryption key not found. Call initialize() first.');
    }
    
    // Convert the key string to an encrypt.Key object
    return encrypt.Key.fromBase64(keyString);
  }
  
  /// Encrypt and save configuration data to a file
  /// 
  /// [data] The configuration data to encrypt and save
  /// [fileName] Optional file name for the encrypted config file
  Future<String> saveEncryptedConfig(Map<String, dynamic> data, {String? fileName}) async {
    // Get the encryption key
    final key = await _getEncryptionKey();
    
    // Generate a random IV
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // Create an encrypter with AES in CBC mode
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    // Convert the data to JSON and encrypt it
    final jsonData = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    
    // Create a map with the IV and encrypted data
    final encryptedData = {
      'iv': iv.base64,
      'data': encrypted.base64,
      'hash': sha256.convert(utf8.encode(jsonData)).toString(),
    };
    
    // Convert the encrypted data to JSON
    final encryptedJson = jsonEncode(encryptedData);
    
    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    
    // Create the file path
    final filePath = '${directory.path}/${fileName ?? _defaultConfigFileName}';
    
    // Write the encrypted data to the file
    await File(filePath).writeAsString(encryptedJson);
    
    return filePath;
  }
  
  /// Load and decrypt configuration data from a file
  /// 
  /// [fileName] Optional file name for the encrypted config file
  /// Returns the decrypted configuration data
  Future<Map<String, dynamic>> loadEncryptedConfig({String? fileName}) async {
    // Get the encryption key
    final key = await _getEncryptionKey();
    
    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    
    // Create the file path
    final filePath = '${directory.path}/${fileName ?? _defaultConfigFileName}';
    
    // Check if the file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Encrypted config file not found: $filePath');
    }
    
    // Read the encrypted data from the file
    final encryptedJson = await file.readAsString();
    
    // Parse the JSON
    final encryptedData = jsonDecode(encryptedJson) as Map<String, dynamic>;
    
    // Get the IV and encrypted data
    final iv = encrypt.IV.fromBase64(encryptedData['iv'] as String);
    final encryptedText = encrypt.Encrypted.fromBase64(encryptedData['data'] as String);
    final hash = encryptedData['hash'] as String;
    
    // Create an encrypter with AES in CBC mode
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    // Decrypt the data
    final decrypted = encrypter.decrypt(encryptedText, iv: iv);
    
    // Verify the hash to ensure data integrity
    final calculatedHash = sha256.convert(utf8.encode(decrypted)).toString();
    if (calculatedHash != hash) {
      throw Exception('Data integrity check failed. The encrypted config file may have been tampered with.');
    }
    
    // Parse the decrypted JSON
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }
  
  /// Check if an encrypted config file exists
  /// 
  /// [fileName] Optional file name for the encrypted config file
  /// Returns true if the file exists, false otherwise
  Future<bool> encryptedConfigExists({String? fileName}) async {
    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    
    // Create the file path
    final filePath = '${directory.path}/${fileName ?? _defaultConfigFileName}';
    
    // Check if the file exists
    return File(filePath).exists();
  }
  
  /// Delete an encrypted config file
  /// 
  /// [fileName] Optional file name for the encrypted config file
  Future<void> deleteEncryptedConfig({String? fileName}) async {
    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    
    // Create the file path
    final filePath = '${directory.path}/${fileName ?? _defaultConfigFileName}';
    
    // Check if the file exists
    final file = File(filePath);
    if (await file.exists()) {
      // Delete the file
      await file.delete();
    }
  }
}