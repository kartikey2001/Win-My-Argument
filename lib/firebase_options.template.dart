// Template file for Firebase options
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '${{secrets.FIREBASE_WEB_API_KEY}}',
    appId: '${{secrets.FIREBASE_WEB_APP_ID}}',
    messagingSenderId: '${{secrets.FIREBASE_MESSAGING_SENDER_ID}}',
    projectId: '${{secrets.FIREBASE_PROJECT_ID}}',
    authDomain: '${{secrets.FIREBASE_AUTH_DOMAIN}}',
    storageBucket: '${{secrets.FIREBASE_STORAGE_BUCKET}}',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${{secrets.FIREBASE_ANDROID_API_KEY}}',
    appId: '${{secrets.FIREBASE_ANDROID_APP_ID}}',
    messagingSenderId: '${{secrets.FIREBASE_MESSAGING_SENDER_ID}}',
    projectId: '${{secrets.FIREBASE_PROJECT_ID}}',
    storageBucket: '${{secrets.FIREBASE_STORAGE_BUCKET}}',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '${{secrets.FIREBASE_IOS_API_KEY}}',
    appId: '${{secrets.FIREBASE_IOS_APP_ID}}',
    messagingSenderId: '${{secrets.FIREBASE_MESSAGING_SENDER_ID}}',
    projectId: '${{secrets.FIREBASE_PROJECT_ID}}',
    storageBucket: '${{secrets.FIREBASE_STORAGE_BUCKET}}',
    iosBundleId: '${{secrets.FIREBASE_IOS_BUNDLE_ID}}',
  );
}
