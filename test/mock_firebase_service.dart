import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseAppPlatform(name: name);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform(name: name ?? defaultFirebaseAppName, options: options);
  }
}

class MockFirebaseAppPlatform extends FirebaseAppPlatform {
  Map<String, dynamic>? pluginConstants;

  MockFirebaseAppPlatform({required String name, FirebaseOptions? options})
      : super(name, options ?? const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
        )) {
    pluginConstants = {'isCrashlyticsCollectionEnabled': true};
  }
}

Future<void> mockFirebaseInitialiseApp() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();
}

Future<T> neverEndingFuture<T>() async {
  // ignore: literal_only_boolean_expressions
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
  }
}