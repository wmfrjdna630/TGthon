import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/fridge_item.dart';
import '../../screens/home/home_page.dart'; // TimeFilter enum 사용

/// 홈페이지의 냉장고 타임라인 위젯
/// 유통기한이 임박한 식품들을 시간순으로 시각화하여 표시
class FridgeTimeline extends StatelessWidget {
  final String userName; // 사용자 이름
  final List<FridgeItem> fridgeItems; // 표시할 냉장고 아이템들
  final TimeFilter currentFilter; // 현재 선택된 시간 필터
  final ValueChanged<TimeFilter> onFilterChanged; // 필터 변경 콜백

  const FridgeTimeline({
    super.key,
    required this.userName,
    required this.fridgeItems,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  /// 시간 필터에 따른 최대 일수 반환
  int get _maxDaysForFilter {
    switch (currentFilter) {
      case TimeFilter.week:
        return 7;
      case TimeFilter.biweek:
        return 14;
      case TimeFilter.month:
        return 30;
    }
  }

  /// 시간 필터 라벨 반환
  String get _filterLabel {
    switch (currentFilter) {
      case TimeFilter.week:
        return '1주';
      case TimeFilter.biweek:
        return '2주';
      case TimeFilter.month:
        return '1개월';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 아이템들을 daysLeft 순으로 정렬 (오름차순)
    final sortedItems = [...fridgeItems]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 헤더 (제목 + 필터 칩들)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$userName 님의 냉장고', style: AppTextStyles.sectionTitle),
              _TimeFilterChips(
                currentFilter: currentFilter,
                onFilterChanged: onFilterChanged,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 타임라인 시각화
          _TimelineVisualization(
            items: sortedItems,
            maxDays: _maxDaysForFilter,
            filterLabel: _filterLabel,
          ),
        ],
      ),
    );
  }
}

/// 시간 필터 칩들
class _TimeFilterChips extends StatelessWidget {
  final TimeFilter currentFilter;
  final ValueChanged<TimeFilter> onFilterChanged;

  const _TimeFilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TimeFilter.values.map((filter) {
        final isSelected = currentFilter == filter;
        String label;
        switch (filter) {
          case TimeFilter.week:
            label = '1주';
            break;
          case TimeFilter.biweek:
            label = '2주';
            break;
          case TimeFilter.month:
            label = '1개월';
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 타임라인 시각화 위젯
class _TimelineVisualization extends StatelessWidget {
  final List<FridgeItem> items;
  final int maxDays;
  final String filterLabel;

  const _TimelineVisualization({
    required this.items,
    required this.maxDays,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const barHeight = 6.0;
        final totalDays = maxDays.toDouble();
        const rowGap = 36.0;
        const labelGap = 22.0;

        return SizedBox(
          height: rowGap * 3 + 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 그라데이션 바 (위험 -> 주의 -> 신선)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      stops: [0.0, 0.25, 1.0],
                      colors: AppColors.timelineGradient,
                    ),
                  ),
                ),
              ),

              // 시작점과 끝점 라벨
              const Positioned(
                top: -labelGap,
                left: 0,
                child: Text('오늘', style: TextStyle(fontSize: 12)),
              ),
              Positioned(
                top: -labelGap,
                right: 0,
                child: Text(filterLabel, style: const TextStyle(fontSize: 12)),
              ),

              // 각 아이템을 정확한 위치에 배치
              ...items.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;

                // 정확한 X축 위치 계산 (daysLeft를 기준으로)
                final d = item.daysLeft.clamp(0, totalDays).toDouble();
                final x = (d / totalDays) * width;

                // 칩의 너비를 고려하여 중앙 정렬 (칩 너비 약 48px로 가정)
                const chipWidth = 48.0;
                final left = (x - chipWidth / 2).clamp(0.0, width - chipWidth);

                // Y축 위치 (3개 레일로 분산)
                final rail = idx % 3;
                final top = 24 + rail * rowGap;

                return Positioned(
                  left: left,
                  top: top,
                  child: _TimelineChip(
                    name: item.name,
                    daysLeft: item.daysLeft,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

/// 타임라인의 개별 아이템 칩
class _TimelineChip extends StatelessWidget {
  final String name;
  final int daysLeft;

  const _TimelineChip({required this.name, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getColorByDaysLeft(daysLeft);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
