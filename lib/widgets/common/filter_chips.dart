import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 공통으로 사용되는 필터 칩 위젯
/// 다양한 페이지에서 재사용 가능한 필터링 UI 제공
class FilterChips extends StatelessWidget {
  final List<FilterChipData> chips; // 칩 데이터 리스트
  final String selectedChip; // 현재 선택된 칩
  final ValueChanged<String> onChipSelected; // 칩 선택 콜백
  final ScrollController? scrollController; // 스크롤 컨트롤러 (선택사항)
  final bool showScrollbar; // 스크롤바 표시 여부
  final EdgeInsets padding; // 패딩

  const FilterChips({
    super.key,
    required this.chips,
    required this.selectedChip,
    required this.onChipSelected,
    this.scrollController,
    this.showScrollbar = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  /// 간단한 텍스트 칩 생성 팩토리
  factory FilterChips.simple({
    required List<String> labels,
    required String selectedLabel,
    required ValueChanged<String> onLabelSelected,
    ScrollController? scrollController,
    bool showScrollbar = false,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 4,
    ),
  }) {
    final chips = labels
        .map((label) => FilterChipData(label: label, value: label))
        .toList();

    return FilterChips(
      chips: chips,
      selectedChip: selectedLabel,
      onChipSelected: onLabelSelected,
      scrollController: scrollController,
      showScrollbar: showScrollbar,
      padding: padding,
    );
  }

  /// 개수가 포함된 칩 생성 팩토리
  factory FilterChips.withCounts({
    required Map<String, int> labelCounts,
    required String selectedLabel,
    required ValueChanged<String> onLabelSelected,
    ScrollController? scrollController,
    bool showScrollbar = false,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 4,
    ),
  }) {
    final chips = labelCounts.entries
        .map(
          (entry) => FilterChipData(
            label: entry.key,
            value: entry.key,
            count: entry.value,
          ),
        )
        .toList();

    return FilterChips(
      chips: chips,
      selectedChip: selectedLabel,
      onChipSelected: onLabelSelected,
      scrollController: scrollController,
      showScrollbar: showScrollbar,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0).withAlpha(77),
        borderRadius: BorderRadius.circular(15),
      ),
      child: _buildChipsList(),
    );
  }

  /// 칩 리스트 빌드
  Widget _buildChipsList() {
    // 스크롤 가능한 칩들
    if (scrollController != null) {
      return _buildScrollableChips();
    }

    // 고정 너비 칩들 (Row로 배치)
    return _buildFixedChips();
  }

  /// 스크롤 가능한 칩들
  Widget _buildScrollableChips() {
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.asMap().entries.map((entry) {
          final index = entry.key;
          final chip = entry.value;
          final isLast = index == chips.length - 1;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: _FilterChip(
              data: chip,
              isSelected: selectedChip == chip.value,
              onTap: () => onChipSelected(chip.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 고정 너비 칩들 (균등 분할)
  Widget _buildFixedChips() {
    return Row(
      children: chips.map((chip) {
        return Expanded(
          child: _FilterChip(
            data: chip,
            isSelected: selectedChip == chip.value,
            onTap: () => onChipSelected(chip.value),
          ),
        );
      }).toList(),
    );
  }
}

/// 필터 칩 데이터 클래스
class FilterChipData {
  final String label; // 표시할 라벨
  final String value; // 실제 값
  final int? count; // 개수 (선택사항)
  final IconData? icon; // 아이콘 (선택사항)
  final Color? color; // 커스텀 색상 (선택사항)

  const FilterChipData({
    required this.label,
    required this.value,
    this.count,
    this.icon,
    this.color,
  });
}

/// 개별 필터 칩 위젯
class _FilterChip extends StatelessWidget {
  final FilterChipData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: data.color ?? AppColors.primary)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 (있는 경우)
            if (data.icon != null) ...[
              Icon(
                data.icon,
                size: 16,
                color: isSelected
                    ? (data.color ?? AppColors.primary)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
            ],

            // 라벨
            Text(
              data.label,
              style: AppTextStyles.filterChip.copyWith(
                color: isSelected
                    ? (data.color ?? AppColors.primary)
                    : Colors.grey.shade600,
              ),
            ),

            // 개수 배지 (있는 경우)
            if (data.count != null) ...[
              const SizedBox(width: 8),
              _CountBadge(
                count: data.count!,
                isSelected: isSelected,
                color: data.color,
              ),
            ],
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
  final Color? color;

  const _CountBadge({
    required this.count,
    required this.isSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? (color ?? AppColors.primary)
            : const Color(0xFFF0F0F0).withAlpha(77),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

/// 특수한 용도의 필터 칩들
class SpecialFilterChips {
  /// 냉장고 위치 필터 칩
  static FilterChips fridgeLocation({
    required String selectedLocation,
    required Map<String, int> locationCounts,
    required ValueChanged<String> onLocationChanged,
  }) {
    return FilterChips.withCounts(
      labelCounts: locationCounts,
      selectedLabel: selectedLocation,
      onLabelSelected: onLocationChanged,
    );
  }

  /// 레시피 카테고리 필터 칩
  static FilterChips recipeCategory({
    required String selectedCategory,
    required Map<String, int> categoryCounts,
    required ValueChanged<String> onCategoryChanged,
    required ScrollController scrollController,
  }) {
    return FilterChips.withCounts(
      labelCounts: categoryCounts,
      selectedLabel: selectedCategory,
      onLabelSelected: onCategoryChanged,
      scrollController: scrollController,
      showScrollbar: true,
    );
  }

  /// 시간 필터 칩 (1주, 2주, 1개월)
  static FilterChips timeFilter({
    required String selectedTime,
    required ValueChanged<String> onTimeChanged,
  }) {
    const timeOptions = ['1주', '2주', '1개월'];

    return FilterChips.simple(
      labels: timeOptions,
      selectedLabel: selectedTime,
      onLabelSelected: onTimeChanged,
    );
  }

  /// 정렬 옵션 칩
  static FilterChips sortOptions({
    required String selectedSort,
    required ValueChanged<String> onSortChanged,
    required List<String> options,
  }) {
    return FilterChips.simple(
      labels: options,
      selectedLabel: selectedSort,
      onLabelSelected: onSortChanged,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  /// 우선순위 필터 칩
  static FilterChips priority({
    required String selectedPriority,
    required ValueChanged<String> onPriorityChanged,
  }) {
    final priorities = [
      FilterChipData(
        label: '높음',
        value: 'high',
        icon: Icons.priority_high,
        color: AppColors.danger,
      ),
      FilterChipData(
        label: '보통',
        value: 'medium',
        icon: Icons.remove,
        color: AppColors.warning,
      ),
      FilterChipData(
        label: '낮음',
        value: 'low',
        icon: Icons.keyboard_arrow_down,
        color: AppColors.success,
      ),
    ];

    return FilterChips(
      chips: priorities,
      selectedChip: selectedPriority,
      onChipSelected: onPriorityChanged,
    );
  }
}
