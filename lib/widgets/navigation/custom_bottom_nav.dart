import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 커스텀 하단 네비게이션 바 위젯
/// 4개 탭 (Home, Fridge, Recipes, To-Do) 제공
class CustomBottomNav extends StatelessWidget {
  final int currentIndex; // 현재 선택된 탭 인덱스
  final ValueChanged<int> onTabChanged; // 탭 변경 콜백

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  /// 네비게이션 아이템 정의
  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.kitchen, label: 'Fridge'),
    _NavItem(icon: Icons.book, label: 'Recipes'),
    _NavItem(icon: Icons.check_box, label: 'To-Do'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return _NavItemWidget(
            item: item,
            isSelected: isSelected,
            onTap: () => onTabChanged(index),
          );
        }).toList(),
      ),
    );
  }
}

/// 네비게이션 아이템 데이터 클래스
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

/// 개별 네비게이션 아이템 위젯
class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 0, 98, 255)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Icon(
              item.icon,
              color: isSelected ? Colors.white : AppColors.navUnselected,
            ),

            const SizedBox(height: 4),

            // 라벨
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.navUnselected,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
