import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/fridge_item.dart';
import '../../screens/home/home_page.dart'; // TimeFilter enum 사용
import 'dart:math' as math;

/// 홈페이지의 냉장고 타임라인 위젯
/// 유통기한이 임박한 식품들을 시간순으로 시각화하여 표시
/// 새로운 색상 체계: 빨간색(1주), 주황색(4주), 초록색(4주 이상)
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
        return 7; // 1주
      case TimeFilter.month:
        return 28; // 1개월 (4주)
      case TimeFilter.third:
        return 90; // 3개월
    }
  }

  /// 시간 필터 라벨 반환
  String get _filterLabel {
    switch (currentFilter) {
      case TimeFilter.week:
        return '1주';
      case TimeFilter.month:
        return '1개월';
      case TimeFilter.third:
        return '3개월';
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
            filterType: _filterLabel,
          ),
        ],
      ),
    );
  }
}

/// 시간 필터 칩들 (새로운 필터 옵션)
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
          case TimeFilter.month:
            label = '1개월';
            break;
          case TimeFilter.third:
            label = '3개월';
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

/// 내부 사용용: 아이템과 계산된 left 좌표 묶음 (레코드 대신 명시 타입)
class _ItemLeft {
  final FridgeItem item;
  final double left;
  _ItemLeft(this.item, this.left);
}

/// 타임라인 시각화 위젯 (겹침 방지 배치)
class _TimelineVisualization extends StatelessWidget {
  final List<FridgeItem> items;
  final int maxDays;
  final String filterLabel;
  final String filterType; // 그라데이션 타입 결정용

  const _TimelineVisualization({
    required this.items,
    required this.maxDays,
    required this.filterLabel,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double barHeight = 6.0;
        const double labelGap = 22.0;

        // 필터에 따른 그라데이션
        final gradientColors = AppColors.getTimelineGradient(filterType);
        final gradientStops = AppColors.getTimelineGradientStops(filterType);

        // 칩 치수/여백 추정치
        const double chipWidth = 64.0; // 4글자 + padding 고려
        const double chipHeight = 28.0;
        const double minGapX = 8.0; // 칩 가로 간격 최소치
        const double rowGap = 36.0; // 레일 간 세로 간격
        const int maxRails = 24; // 안전 상한 (필요시 늘려도 됨)

        // X 위치 계산을 위한 스케일
        final double totalDays = maxDays.toDouble();

        // 1) 각 아이템의 target-left 계산 후 x 기준 정렬
        final List<_ItemLeft> itemsWithLeft = items.map((item) {
          final double d = item.daysLeft.clamp(0, totalDays).toDouble();
          final double x = (d / totalDays) * width;
          final double left = (x - chipWidth / 2)
              .clamp(0.0, math.max(0.0, width - chipWidth))
              .toDouble();
          return _ItemLeft(item, left);
        }).toList()..sort((a, b) => a.left.compareTo(b.left));

        // 2) 스윕라인: 겹침 없이 위로 쌓기
        final List<double> railRightEdge = []; // 레일별 마지막 칩의 right
        final List<int> railOfIndex = List.filled(itemsWithLeft.length, 0);

        for (int i = 0; i < itemsWithLeft.length; i++) {
          final double left = itemsWithLeft[i].left;
          final double right = left + chipWidth;

          int placedRail = -1;
          for (int r = 0; r < railRightEdge.length; r++) {
            if (left >= railRightEdge[r] + minGapX) {
              placedRail = r;
              railRightEdge[r] = right;
              break;
            }
          }
          if (placedRail == -1) {
            // 새 레일 생성
            railRightEdge.add(right);
            placedRail = railRightEdge.length - 1;
          }
          railOfIndex[i] = placedRail;
          if (railRightEdge.length >= maxRails) break; // 상한 보호
        }

        final int railsUsed = math.max(3, railRightEdge.length); // 최소 3줄 유지
        final double totalHeight = 24 + railsUsed * rowGap;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 상단 그라데이션 바
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      stops: gradientStops,
                      colors: gradientColors,
                    ),
                  ),
                ),
              ),

              // 시작/끝 라벨
              const Positioned(
                top: -labelGap + 4,
                left: 0,
                child: Text('오늘', style: TextStyle(fontSize: 11)),
              ),
              Positioned(
                top: -labelGap + 4,
                right: 0,
                child: Text(filterLabel, style: const TextStyle(fontSize: 11)),
              ),

              // 3) 배치된 좌표로 칩 렌더링
              ...List.generate(itemsWithLeft.length, (i) {
                final _ItemLeft entry = itemsWithLeft[i];
                final FridgeItem item = entry.item;
                final double left = entry.left;
                final int rail = railOfIndex[i];
                final double top = 24 + rail * rowGap;

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

/// 타임라인의 개별 아이템 칩 (새로운 색상 시스템 적용)
class _TimelineChip extends StatelessWidget {
  final String name;
  final int daysLeft;

  const _TimelineChip({required this.name, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    // 새로운 색상 기준 적용
    final Color bg = AppColors.getColorByDaysLeft(daysLeft);

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
        name.length > 4 ? name.substring(0, 4) : name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
