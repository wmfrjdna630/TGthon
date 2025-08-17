import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 레시피 페이지의 필터 칩들 위젯
/// 가로 스크롤 가능한 필터 칩들과 개수 배지 제공
class RecipeFilterChips extends StatelessWidget {
  final String selectedFilter; // 현재 선택된 필터
  final Map<String, int> filterCounts; // 각 필터별 레시피 개수
  final ValueChanged<String> onFilterChanged; // 필터 변경 콜백
  final ScrollController scrollController; // 스크롤 컨트롤러

  const RecipeFilterChips({
    super.key,
    required this.selectedFilter,
    required this.filterCounts,
    required this.onFilterChanged,
    required this.scrollController,
  });

  /// 기본 필터 목록
  static const List<String> _filterLabels = [
    'Can make now',
    'Almost ready',
    'Quick meals',
    'Vegetarian',
  ];

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        // 스크롤 메트릭 변경 시 부모 위젯에 알림
        if (notification.metrics.axis == Axis.horizontal) {
          // 스크롤바 업데이트를 위한 알림
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              // 부모 위젯의 setState 호출을 위한 트릭
              (context as Element).markNeedsBuild();
            }
          });
        }
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_filterLabels.length, (index) {
              final label = _filterLabels[index];
              final isSelected = selectedFilter == label;
              final count = filterCounts[label] ?? 0;
              final isLast = index == _filterLabels.length - 1;

              return Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: _FilterChip(
                  label: label,
                  count: count,
                  isSelected: isSelected,
                  onTap: () => onFilterChanged(label),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 개별 필터 칩
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.filterSelected
              : AppColors.filterUnselected,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.filterBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 필터 라벨
            Text(
              label,
              style: AppTextStyles.filterChip.copyWith(
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),

            const SizedBox(width: 6),

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.filterBorder,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
