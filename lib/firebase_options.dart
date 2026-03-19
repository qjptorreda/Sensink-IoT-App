import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBo4Ourmg3uZ1ZOD7Ns2od8jajSBrVWhCU",
    authDomain: "sensink-appdev.firebaseapp.com",
    projectId: "sensink-appdev",
    storageBucket: "sensink-appdev.firebasestorage.app",
    messagingSenderId: "837308570802",
    appId: "1:837308570802:web:8e2307ef8bdf101d88bdab",
    measurementId: "G-92Y8KM1FJT",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBo4Ourmg3uZ1ZOD7Ns2od8jajSBrVWhCU",
    projectId: "sensink-appdev",
    storageBucket: "sensink-appdev.firebasestorage.app",
    messagingSenderId: "837308570802",
    // PASTE YOUR ANDROID APP ID BELOW (Found in Firebase Settings)
    appId: "1:837308570802:android:a88d9d66d0aa2b7788bdab", 
  );
}