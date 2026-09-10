import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
  apiKey: "AIzaSyByGMXwTAtG-eNe1whswK-v553eUukoI1U",
  authDomain: "proflu-4d096.firebaseapp.com",
  projectId: "proflu-4d096",
  storageBucket: "proflu-4d096.firebasestorage.app",
  messagingSenderId: "224004806180",
  appId: "1:224004806180:web:4d0383648b60f928252ab1"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForProfluAndroid123456',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'proflu',
    storageBucket: 'proflu.appspot.com',
  );
}