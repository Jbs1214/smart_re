// firebase_options.dart

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
    apiKey: 'AIzaSyDTKVzxhZ8HJqy86UW1hMvCG1jSwEd2lEI',
    appId: '1:815209381949:web:75d265f37539dadce32a54',
    messagingSenderId: '815209381949',
    projectId: 'rasptoapp',
    authDomain: 'rasptoapp-c704a.firebaseapp.com',
    storageBucket: 'rasptoapp.appspot.com',
    measurementId: 'G-6H278FR1XK',
    databaseURL: 'https://rasptoapp-default-rtdb.asia-southeast1.firebasedatabase.app', // 추가된 부분
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCK-b4_YlSCcim9KC7Zj8OzLQYgbHaKoYw',
    appId: '1:815209381949:android:e1ab5502c8b6d74be32a54',
    messagingSenderId: '815209381949',
    projectId: 'rasptoapp',
    storageBucket: 'rasptoapp.appspot.com',
    databaseURL: 'https://rasptoapp-default-rtdb.asia-southeast1.firebasedatabase.app', // 추가된 부분
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXbErWZ6MqHuVOn4x3agEnoGBrFmEOK4I',
    appId: '1:815209381949:ios:be18a6924c965a8ee32a54',
    messagingSenderId: '815209381949',
    projectId: 'rasptoapp',
    storageBucket: 'rasptoapp.appspot.com',
    androidClientId: '815209381949-iiv4cqp3bi0r5ri6sa1g874kre2v6nm1.apps.googleusercontent.com',
    iosClientId: '815209381949-l13d6chl18vj8l09vk86t2i7r07tbpkq.apps.googleusercontent.com',
    iosBundleId: 'com.example.untitled1',
    databaseURL: 'https://rasptoapp-default-rtdb.asia-southeast1.firebasedatabase.app', // 추가된 부분
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBXbErWZ6MqHuVOn4x3agEnoGBrFmEOK4I',
    appId: '1:815209381949:ios:be18a6924c965a8ee32a54',
    messagingSenderId: '815209381949',
    projectId: 'rasptoapp',
    storageBucket: 'rasptoapp.appspot.com',
    androidClientId: '815209381949-iiv4cqp3bi0r5ri6sa1g874kre2v6nm1.apps.googleusercontent.com',
    iosClientId: '815209381949-l13d6chl18vj8l09vk86t2i7r07tbpkq.apps.googleusercontent.com',
    iosBundleId: 'com.example.untitled1',
    databaseURL: 'https://rasptoapp-default-rtdb.asia-southeast1.firebasedatabase.app', // 추가된 부분
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDTKVzxhZ8HJqy86UW1hMvCG1jSwEd2lEI',
    appId: '1:815209381949:web:ecd03aaba967a252e32a54',
    messagingSenderId: '815209381949',
    projectId: 'rasptoapp',
    authDomain: 'rasptoapp-c704a.firebaseapp.com',
    storageBucket: 'rasptoapp.appspot.com',
    measurementId: 'G-L2GY5XRV2H',
    databaseURL: 'https://rasptoapp-default-rtdb.asia-southeast1.firebasedatabase.app', // 추가된 부분
  );
}
