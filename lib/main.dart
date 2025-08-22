import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (_) {
      await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
    }
  }
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
  // 4) 앱 시작
  runApp(const App());
}

/// 익명 로그인 보장: 이미 로그인돼 있으면 재로그인 안 함.
/// 실패 시 짧게 재시도하고, 끝내 실패하면 명확히 에러를 던져서
/// 나중에 Firestore에서 permission-denied로 헷갈리지 않게 한다.
Future<void> _ensureAnonymousSignIn() async {
  final auth = FirebaseAuth.instance;

  // 이미 로그인됨
  if (auth.currentUser != null) {
    _log('Already signed in as uid=${auth.currentUser!.uid}');
    return;
  }

  const maxAttempts = 3;
  Object? lastError;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final cred = await auth.signInAnonymously();
      _log('Signed in anonymously as uid=${cred.user?.uid}');
      return;
    } catch (e) {
      lastError = e;
      _log('Anonymous sign-in failed (attempt $attempt/$maxAttempts): $e');
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  // 여기서 멈추면 이후 Firestore 경로에서 uid null로 죽는 것보다
  // 로그인 실패 원인이 바로 드러나서 디버깅이 쉬움.
  throw StateError('Anonymous sign-in failed: $lastError');
}

void _log(Object o) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(o);
  }
}
