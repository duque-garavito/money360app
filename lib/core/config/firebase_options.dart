import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyAWyNGegiBizbnGZueRCCaX3TwhXrForXo',
      appId: '1:635327572596:web:53f5d2697877df86933f21',
      messagingSenderId: '635327572596',
      projectId: 'money360-ce04b',
      authDomain: 'money360-ce04b.firebaseapp.com',
      storageBucket: 'money360-ce04b.firebasestorage.app',
    );
  }
}
