import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAet0x52b_oyZjSbq1fGx_GG1OCRTPSI7s',
    appId: '1:690998693907:android:aa8d37f577a4c389f52fe6',
    messagingSenderId: '690998693907',
    projectId: 'steptracker-82475',
    storageBucket: 'steptracker-82475.firebasestorage.app',
  );

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyCukUwJygRH7ucS1iZtn6QctYJH0pcGAhM',
    appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '1:690998693907:web:ae76285ab5c8cb88f52fe6',
    messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '690998693907',
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID'] ?? 'steptracker-82475',
    authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? 'steptracker-82475.firebaseapp.com',
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'] ?? 'steptracker-82475.firebasestorage.app',
    measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'],
  );
}
