import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure가 생성
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

// 👇 익명 로그인 (처음 한 번)
  try {
    await FirebaseAuth.instance.signInAnonymously();
    // print('Signed in anonymously as ${FirebaseAuth.instance.currentUser?.uid}');
  } catch (e) {
    // print('Anonymous sign-in failed: $e');
  }

  runApp(const App());
}