import 'package:flutter/material.dart';
import 'features/shell/main_shell.dart';

/// 메인 앱 클래스
/// MaterialApp 설정 및 전체 앱 테마 관리
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Fridge Manager',
      debugShowCheckedModeBanner: false,

      // 앱 테마 설정
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF34C965), // 메인 브랜드 색상
        ),
        useMaterial3: true,

        // AppBar 테마
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),

        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF34C965), width: 2),
          ),
        ),

        // ElevatedButton 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34C965),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Card 테마
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),

      // 메인 쉘로 이동
      home: const MainShell(),
    );
  }
}
