import 'package:flutter/material.dart';
import '../../widgets/navigation/custom_bottom_nav.dart';
import '../../screens/home/home_page.dart';
import '../../screens/fridge/fridge_page.dart';
import '../../screens/recipes/recipes_page.dart';
import '../../screens/todo/todo_page.dart';

/// 메인 앱 쉘 - 네비게이션과 페이지 관리
/// 하단 네비게이션으로 4개 페이지 간 전환 제공
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // ========== 상태 변수들 ==========

  /// 현재 선택된 탭 인덱스
  int _currentIndex = 0;

  /// 페이지들 (IndexedStack으로 상태 유지)
  final List<Widget> _pages = const [
    HomePage(), // 0: 홈
    FridgePage(), // 1: 냉장고
    RecipesPage(), // 2: 레시피
    TodoPage(), // 3: 할일
  ];

  // ========== 빌드 메서드 ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 페이지 영역 (IndexedStack으로 상태 보존)
      body: IndexedStack(index: _currentIndex, children: _pages),

      // 하단 네비게이션 바
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }

  // ========== 이벤트 핸들러들 ==========

  /// 탭 변경 처리
  void _onTabChanged(int newIndex) {
    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }
}
