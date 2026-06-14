// TODO: REPLACE THIS ENTIRE FILE with the output of `flutterfire configure`.
//
// Steps to generate the real firebase_options.dart:
//
//   1. Install the FlutterFire CLI (one-time):
//        dart pub global activate flutterfire_cli
//
//   2. Log in to Firebase:
//        firebase login
//
//   3. From the project root, run:
//        flutterfire configure
//
//      Follow the prompts to select your Firebase project and the platforms
//      (Android, iOS, Web, etc.) you want to configure.
//
//   4. The CLI will overwrite this file with real, project-specific values.
//
//   5. Do NOT commit the generated file if it contains sensitive keys — add
//      lib/core/constants/firebase_options.dart to .gitignore if needed, or
//      use environment-specific build flavors.
//
// The stub below keeps the project compilable before real credentials are added.
// Firebase.initializeApp() will fail at runtime until you replace this file.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Stub [FirebaseOptions] — REPLACE with output from `flutterfire configure`.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '${defaultTargetPlatform.name}. '
          'Run `flutterfire configure` to generate real options.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // STUB VALUES — all placeholders, not real credentials.
  // ---------------------------------------------------------------------------

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId:
        '000000000000-PLACEHOLDER.apps.googleusercontent.com',
    iosBundleId: 'com.yourcompany.omega',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'PLACEHOLDER_MACOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId:
        '000000000000-PLACEHOLDER.apps.googleusercontent.com',
    iosBundleId: 'com.yourcompany.omega',
  );
}
