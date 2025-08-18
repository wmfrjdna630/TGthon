import 'package:flutter/material.dart';
import 'features/shell/main_shell.dart';

/// 메인 앱 클래스
/// MaterialApp 설정 및 전체 앱 테마 관리 (파랑색 테마)
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Fridge Manager',
      debugShowCheckedModeBanner: false,

      // 앱 테마 설정 (파랑색 테마)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // 메인 파랑색
          background: const Color(0xFFF0F8FF), // 연한 하늘색 배경
        ),
        useMaterial3: true,

        // 전체 배경색 설정
        scaffoldBackgroundColor: const Color(0xFFF0F8FF), // 연한 하늘색
        // AppBar 테마 (파랑색)
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF2196F3), // 파랑색 배경
          foregroundColor: Colors.white, // 흰색 텍스트
        ),

        // 입력 필드 테마 (파랑색 포커스)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2196F3),
              width: 2,
            ), // 파랑색 포커스
          ),
          filled: true,
          fillColor: Colors.white, // 입력 필드 배경 흰색
        ),

        // ElevatedButton 테마 (파랑색)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3), // 파랑색 배경
            foregroundColor: Colors.white, // 흰색 텍스트
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),

        // Card 테마 (흰색 배경에 그림자)
        cardTheme: CardThemeData(
          elevation: 4,
          color: Colors.white, // 카드 배경 흰색
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          shadowColor: const Color(0xFF2196F3).withOpacity(0.1), // 파랑색 그림자
        ),

        // FloatingActionButton 테마
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2196F3), // 파랑색
          foregroundColor: Colors.white,
        ),

        // BottomNavigationBar 테마
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF2196F3), // 파랑색 배경
          selectedItemColor: Colors.white, // 선택된 아이템 흰색
          unselectedItemColor: Color(0xFFBBDEFB), // 선택안된 아이템 연한 파랑
          elevation: 8,
        ),

        // Chip 테마
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE3F2FD), // 연한 파랑 배경
          selectedColor: const Color(0xFF2196F3), // 선택시 파랑
          labelStyle: const TextStyle(color: Colors.black87),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // ProgressIndicator 색상
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF2196F3), // 파랑색
        ),

        // Switch/Checkbox 테마
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF2196F3); // 파랑색
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF64B5F6); // 밝은 파랑
            }
            return Colors.grey.shade300;
          }),
        ),

        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF2196F3); // 파랑색
            }
            return Colors.transparent;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
      ),

      // 메인 쉘로 이동
      home: const MainShell(),
    );
  }
}
