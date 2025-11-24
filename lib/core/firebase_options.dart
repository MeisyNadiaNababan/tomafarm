// File: firebase_options.dart
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
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCOVU5L97FVBf3s5u-lIVWaAwN_umcXGpY',
    appId: '1:775637856733:web:d25d0ca3e84d54208c8634',
    messagingSenderId: '775637856733',
    projectId: 'tomafarm-pbl',
    authDomain: 'tomafarm-pbl.firebaseapp.com',
    storageBucket: 'tomafarm-pbl.firebasestorage.app',
    measurementId: 'G-QSZ3FWYRZZ',
    databaseURL: 'https://tomafarm-pbl-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0LEU5ruzE5aACQdEuherNH0mnwdB-AJw',
    appId: '1:775637856733:android:5450d921c77583e18c8634',
    messagingSenderId: '775637856733',
    projectId: 'tomafarm-pbl',
    storageBucket: 'tomafarm-pbl.firebasestorage.app',
    databaseURL: 'https://tomafarm-pbl-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDiqCXPrqTzWO9dz3tpKUAF08DgVVDrUWc',
    appId: '1:775637856733:ios:df2bb31a4e7f9bcb8c8634',
    messagingSenderId: '775637856733',
    projectId: 'tomafarm-pbl',
    storageBucket: 'tomafarm-pbl.firebasestorage.app',
    iosBundleId: 'com.example.tomafarm',
    databaseURL: 'https://tomafarm-pbl-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDiqCXPrqTzWO9dz3tpKUAF08DgVVDrUWc',
    appId: '1:775637856733:ios:df2bb31a4e7f9bcb8c8634',
    messagingSenderId: '775637856733',
    projectId: 'tomafarm-pbl',
    storageBucket: 'tomafarm-pbl.firebasestorage.app',
    iosBundleId: 'com.example.tomafarm',
    databaseURL: 'https://tomafarm-pbl-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCOVU5L97FVBf3s5u-lIVWaAwN_umcXGpY',
    appId: '1:775637856733:web:319bd3a39fa3cb5b8c8634',
    messagingSenderId: '775637856733',
    projectId: 'tomafarm-pbl',
    authDomain: 'tomafarm-pbl.firebaseapp.com',
    storageBucket: 'tomafarm-pbl.firebasestorage.app',
    measurementId: 'G-60HVB83NHL',
    databaseURL: 'https://tomafarm-pbl-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}