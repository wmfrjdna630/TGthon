import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          return Expanded(
            child: _NavItemWidget(
              key: ValueKey(item.label),
              item: item,
              isSelected: index == currentIndex,
              onTap: () => onTabChanged(index),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedIconColor = Color(0xFF0000FF);
    final unselectedColor = AppColors.navUnselected;

    return RepaintBoundary(
      // ← 다른 탭 리페인트 방지
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.black12.withOpacity(0.05),
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: AnimatedContainer(
            duration: isSelected
                ? const Duration(milliseconds: 200)
                : Duration.zero, // ← 선택 탭만 애니메이션
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? selectedIconColor : unselectedColor,
                ),
                const SizedBox(height: 4),
                // 글자 굵기는 고정 → 폭 변동 없게
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? selectedIconColor : unselectedColor,
                    fontWeight: FontWeight.w600, // ← 고정
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
