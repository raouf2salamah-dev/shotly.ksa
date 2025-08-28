import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

void setupFirebaseAuthMocks([String customAuthPath = '']) {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/firebase_auth');
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'Auth#registerIdTokenListener') {
      return null;
    }
    if (methodCall.method == 'Auth#registerAuthStateListener') {
      return null;
    }
    throw UnimplementedError(methodCall.method);
  });
}

class MockFirebaseCoreHostApi implements firebase_core.FirebaseCoreHostApi {
  @override
  Future<List<firebase_core.PigeonInitializeResponse>> initializeCore() async {
    return <firebase_core.PigeonInitializeResponse>[
      firebase_core.PigeonInitializeResponse(
        name: '[DEFAULT]',
        options: firebase_core.PigeonFirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
        ),
        pluginConstants: <String, dynamic>{
          'plugins.flutter.io/firebase_crashlytics': <String, dynamic>{
            'isCrashlyticsCollectionEnabled': true,
          },
        },
      ),
    ];
  }

  @override
  Future<firebase_core.PigeonInitializeResponse> initializeApp(
      String name, firebase_core.PigeonFirebaseOptions options) async {
    return firebase_core.PigeonInitializeResponse(
      name: name,
      options: options,
      pluginConstants: <String, dynamic>{
        'plugins.flutter.io/firebase_crashlytics': <String, dynamic>{
          'isCrashlyticsCollectionEnabled': true,
        },
      },
    );
  }

  @override
  Future<Map<String, dynamic>> optionsFromResource() async {
    return <String, dynamic>{};
  }
}

Future<void> mockFirebaseInitialiseApp() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  firebase_core.FirebaseCoreHostApi.setup(MockFirebaseCoreHostApi());
  await Firebase.initializeApp();
}