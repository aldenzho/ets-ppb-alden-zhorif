// File ini auto-generated oleh Firebase CLI
// Update dengan credentials dari Firebase Console Anda

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by run the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_ni8a62GG-6Ve3QOk71ND8ydx3x5Engg',
    appId: '1:317105168007:web:412f1c238d81495838e222',
    messagingSenderId: '317105168007',
    projectId: 'fir-ets-c4afb',
    authDomain: 'fir-ets-c4afb.firebaseapp.com',
    storageBucket: 'fir-ets-c4afb.firebasestorage.app',
    measurementId: 'G-6C1STLNTYD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUTJqyMiCsoOStM_SU05TP5TdOb6mdqYk',
    appId: '1:317105168007:android:28b996ad4ccfe14438e222',
    messagingSenderId: '317105168007',
    projectId: 'fir-ets-c4afb',
    storageBucket: 'fir-ets-c4afb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA1Avx6Xd9npfBgxUpPE_Ug_Yc-mAkTcnI',
    appId: '1:317105168007:ios:9bb779c8b3e60b8c38e222',
    messagingSenderId: '317105168007',
    projectId: 'fir-ets-c4afb',
    storageBucket: 'fir-ets-c4afb.firebasestorage.app',
    iosBundleId: 'com.example.ets',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA1Avx6Xd9npfBgxUpPE_Ug_Yc-mAkTcnI',
    appId: '1:317105168007:ios:9bb779c8b3e60b8c38e222',
    messagingSenderId: '317105168007',
    projectId: 'fir-ets-c4afb',
    storageBucket: 'fir-ets-c4afb.firebasestorage.app',
    iosBundleId: 'com.example.ets',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA_ni8a62GG-6Ve3QOk71ND8ydx3x5Engg',
    appId: '1:317105168007:web:8650b8a90b5f413438e222',
    messagingSenderId: '317105168007',
    projectId: 'fir-ets-c4afb',
    authDomain: 'fir-ets-c4afb.firebaseapp.com',
    storageBucket: 'fir-ets-c4afb.firebasestorage.app',
    measurementId: 'G-SFB3JKB1WR',
  );

}