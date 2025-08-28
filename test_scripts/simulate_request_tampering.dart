import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

/// This script simulates request tampering scenarios to test signature validation
/// 
/// It creates a mock server that validates HMAC-SHA256 signatures and tests:
/// 1. Valid signature (should succeed)
/// 2. Tampered path (should fail)
/// 3. Tampered body (should fail)
/// 4. Tampered timestamp (should fail)
/// 5. Missing signature (should fail)
void main() async {
  // Create a mock server
  final mockServer = MockServer();
  await mockServer.start();
  
  print('🔧 Mock server started on port ${mockServer.port}');
  
  // Store a device signing key
  const signingKey = 'test_signing_key_12345';
  await storeDeviceSigningKey(signingKey);
  print('🔑 Device signing key stored: $signingKey');
  
  // Create a client
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${mockServer.port}'));
  
  // Test cases
  await runTest(dio, 'Valid request', '/api/data', '{"test":"data"}', true);
  await runTest(dio, 'Tampered path', '/api/hacked', '{"test":"data"}', false);
  await runTest(dio, 'Tampered body', '/api/data', '{"test":"hacked"}', false);
  await runTest(dio, 'Tampered timestamp', '/api/data', '{"test":"data"}', false, tamperTimestamp: true);
  await runTest(dio, 'Missing signature', '/api/data', '{"test":"data"}', false, skipSignature: true);
  
  // Cleanup
  await mockServer.stop();
  print('\n🧹 Mock server stopped');
}

/// Run a test case
Future<void> runTest(Dio dio, String testName, String path, String body, bool shouldSucceed, 
    {bool tamperTimestamp = false, bool skipSignature = false}) async {
  print('\n🧪 TEST: $testName');
  
  try {
    // Generate timestamp
    final timestamp = tamperTimestamp 
        ? (DateTime.now().millisecondsSinceEpoch - 3600000).toString() // 1 hour old
        : DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create request options
    final options = Options(headers: {'X-Timestamp': timestamp});
    
    // Sign the request (unless we're testing missing signature)
    if (!skipSignature) {
      final signature = await signRequest(path, body, timestamp);
      options.headers!['X-Signature'] = signature;
      print('📝 Generated signature: $signature');
    } else {
      print('⚠️ Skipping signature generation');
    }
    
    // Make the request
    print('🚀 Making request to $path with body: $body');
    final response = await dio.post(path, data: body, options: options);
    
    print('✅ Request succeeded with status ${response.statusCode}');
    print('📄 Response: ${response.data}');
    
    if (!shouldSucceed) {
      print('❌ Test failed: Request should have been rejected');
    } else {
      print('✅ Test passed: Request succeeded as expected');
    }
  } catch (e) {
    print('❌ Request failed: ${e is DioError ? e.response?.data ?? e.message : e}');
    
    if (shouldSucceed) {
      print('❌ Test failed: Request should have succeeded');
    } else {
      print('✅ Test passed: Request was rejected as expected');
    }
  }
}

/// Mock server implementation
class MockServer {
  final port = 8081;
  HttpServer? _server;
  final signingKey = 'test_signing_key_12345';
  
  Future<void> start() async {
    _server = await HttpServer.bind('localhost', port);
    
    _server!.listen((request) async {
      print('\n📨 Received ${request.method} request to ${request.uri.path}');
      
      // Enable CORS
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', '*');
      
      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }
      
      // Read request body
      final body = await utf8.decoder.bind(request).join();
      
      // Verify signature
      final result = verifySignature(request, body);
      
      if (result['valid']) {
        // Valid signature
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'success': true,
          'message': 'Request authenticated successfully',
          'data': {'timestamp': DateTime.now().toIso8601String()}
        }));
      } else {
        // Invalid signature
        request.response.statusCode = 401;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'success': false,
          'error': result['error'],
        }));
      }
      
      await request.response.close();
    });
  }
  
  /// Verify the request signature
  Map<String, dynamic> verifySignature(HttpRequest request, String body) {
    // Get headers
    final signature = request.headers.value('x-signature');
    final timestamp = request.headers.value('x-timestamp');
    
    // Check if all required headers are present
    if (signature == null) {
      print('❌ Missing signature header');
      return {'valid': false, 'error': 'Missing signature header'};
    }
    
    if (timestamp == null) {
      print('❌ Missing timestamp header');
      return {'valid': false, 'error': 'Missing timestamp header'};
    }
    
    // Check timestamp freshness (prevent replay attacks)
    final requestTime = int.parse(timestamp);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final fiveMinutes = 5 * 60 * 1000; // 5 minutes in milliseconds
    
    if (currentTime - requestTime > fiveMinutes) {
      print('❌ Request expired (timestamp too old)');
      return {'valid': false, 'error': 'Request expired'};
    }
    
    // Recreate the signature
    final path = request.uri.path;
    final payload = utf8.encode('$path|$body|$timestamp');
    final hmac = Hmac(sha256, utf8.encode(signingKey));
    final digest = hmac.convert(payload);
    final expectedSignature = base64Encode(digest.bytes);
    
    print('🔍 Expected signature: $expectedSignature');
    print('🔍 Received signature: $signature');
    
    // Compare signatures
    if (signature != expectedSignature) {
      print('❌ Invalid signature');
      return {'valid': false, 'error': 'Invalid signature'};
    }
    
    print('✅ Valid signature');
    return {'valid': true};
  }
  
  Future<void> stop() async {
    await _server?.close();
  }
}

/// Mock secure storage functions
Map<String, String> _secureStorage = {};

Future<void> storeDeviceSigningKey(String signingKey) async {
  _secureStorage['device_signing_key'] = signingKey;
}

Future<String?> getDeviceSigningKey() async {
  return _secureStorage['device_signing_key'];
}

/// Sign a request using HMAC-SHA256
Future<String> signRequest(String path, String body, String timestamp) async {
  final signingKey = await getDeviceSigningKey();
  if (signingKey == null) throw Exception('No signing key available');
  
  // Use pipe delimiter between components for better security
  final payload = utf8.encode('$path|$body|$timestamp');
  final hmac = Hmac(sha256, utf8.encode(signingKey));
  return base64Encode(hmac.convert(payload).bytes);
}