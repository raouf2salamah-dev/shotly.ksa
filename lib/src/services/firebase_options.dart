// This file contains the Firebase options configuration for the application.
// You will need to replace these placeholder values with your actual Firebase configuration.
// To generate this file properly, use the FlutterFire CLI: https://firebase.google.com/docs/flutter/setup

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase options for this application
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Replace these placeholder values with your actual Firebase configuration
  // from the Firebase console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA-Ng77iMdv5D6zj_WLT9wOEnD3odY0NSc',
    appId: '1:218714911108:web:93d001779fdc2f16572dd1',
    messagingSenderId: '218714911108',
    projectId: 'shotly-ksa',
    authDomain: 'shotly-ksa.firebaseapp.com',
    storageBucket: 'shotly-ksa.appspot.com',
    // measurementId removed - was placeholder value causing issues
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-Ng77iMdv5D6zj_WLT9wOEnD3odY0NSc',
    appId: '1:218714911108:android:93d001779fdc2f16572dd1',
    messagingSenderId: '218714911108',
    projectId: 'shotly-ksa',
    storageBucket: 'shotly-ksa.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-ACTUAL-API-KEY', // From GoogleService-Info.plist (API_KEY)
    appId: 'YOUR-ACTUAL-APP-ID', // From GoogleService-Info.plist (GOOGLE_APP_ID)
    messagingSenderId: '218714911108', // From GoogleService-Info.plist (GCM_SENDER_ID)
    projectId: 'shotly-ksa',
    storageBucket: 'shotly-ksa.appspot.com',
    iosClientId: 'YOUR-ACTUAL-CLIENT-ID', // From GoogleService-Info.plist (CLIENT_ID)
    iosBundleId: 'com.shotly.shotly',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );
}