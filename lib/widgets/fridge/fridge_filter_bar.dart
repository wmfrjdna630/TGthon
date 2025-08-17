import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 냉장고 페이지의 필터 바 위젯
/// All, Fridge, Freezer, Pantry 위치별 필터링 제공
class FridgeFilterBar extends StatelessWidget {
  final String selectedFilter; // 현재 선택된 필터
  final Map<String, int> filterCounts; // 각 필터별 아이템 개수
  final ValueChanged<String> onFilterChanged; // 필터 변경 콜백

  const FridgeFilterBar({
    super.key,
    required this.selectedFilter,
    required this.filterCounts,
    required this.onFilterChanged,
  });

  /// 기본 필터 목록
  static const List<String> _filterKeys = [
    'All',
    'Fridge',
    'Freezer',
    'Pantry',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0).withAlpha(77),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: _filterKeys.map((key) {
          final isSelected = selectedFilter == key;
          final count = filterCounts[key] ?? 0;

          return Expanded(
            child: _FilterButton(
              label: key,
              count: count,
              isSelected: isSelected,
              onTap: () => onFilterChanged(key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 개별 필터 버튼
class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 필터 라벨
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),

            const SizedBox(width: 8),

            // 개수 배지
            _CountBadge(count: count, isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

/// 개수 표시 배지
class _CountBadge extends StatelessWidget {
  final int count;
  final bool isSelected;

  const _CountBadge({required this.count, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFF0F0F0).withAlpha(77)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
