import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 레시피 필터 칩용 커스텀 스크롤바 위젯
/// 가로 스크롤 진행률과 좌우 화살표 버튼 제공
class ChipScrollbar extends StatelessWidget {
  final ScrollController scrollController; // 연동할 스크롤 컨트롤러
  final double trackWidth; // 스크롤바 트랙 너비 (화면 너비)

  const ChipScrollbar({
    super.key,
    required this.scrollController,
    required this.trackWidth,
  });

  /// 최소 썸브 크기
  static const double _minThumbSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 스크롤바 계산
        final scrollData = _calculateScrollbarData(constraints.maxWidth);

        return Row(
          children: [
            // 왼쪽 화살표 버튼
            _ArrowButton(
              icon: Icons.arrow_left,
              onPressed: scrollData.canScroll
                  ? () => _scrollBy(-scrollData.viewportDimension / 2)
                  : null,
            ),

            // 스크롤바 트랙
            Expanded(
              child: _ScrollbarTrack(
                scrollData: scrollData,
                onDragUpdate: _onDragUpdate,
                onTapDown: _onTapDown,
              ),
            ),

            // 오른쪽 화살표 버튼
            _ArrowButton(
              icon: Icons.arrow_right,
              onPressed: scrollData.canScroll
                  ? () => _scrollBy(scrollData.viewportDimension / 2)
                  : null,
            ),
          ],
        );
      },
    );
  }

  /// 스크롤바 데이터 계산
  _ScrollbarData _calculateScrollbarData(double trackWidth) {
    double thumbWidth = trackWidth;
    double thumbLeft = 0;
    bool canScroll = false;
    double viewportDimension = 0;
    double maxScrollExtent = 0;
    double currentOffset = 0;

    if (scrollController.hasClients) {
      final position = scrollController.position;
      viewportDimension = position.viewportDimension;
      maxScrollExtent = position.maxScrollExtent;
      currentOffset = position.pixels;
      canScroll = maxScrollExtent > 0;

      if (canScroll) {
        final totalWidth = maxScrollExtent + viewportDimension;
        thumbWidth = (trackWidth * (viewportDimension / totalWidth)).clamp(
          _minThumbSize,
          trackWidth,
        );

        final denominator = (totalWidth - viewportDimension);
        final fraction = denominator > 0
            ? (currentOffset / denominator).clamp(0.0, 1.0)
            : 0.0;
        thumbLeft = (trackWidth - thumbWidth) * fraction;
      }
    }

    return _ScrollbarData(
      thumbWidth: thumbWidth,
      thumbLeft: thumbLeft,
      canScroll: canScroll,
      viewportDimension: viewportDimension,
      maxScrollExtent: maxScrollExtent,
      currentOffset: currentOffset,
      trackWidth: trackWidth,
    );
  }

  /// 스크롤 이동
  void _scrollBy(double delta) {
    if (!scrollController.hasClients) return;

    final target = (scrollController.offset + delta).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );

    scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// 드래그 업데이트 처리
  void _onDragUpdate(DragUpdateDetails details, _ScrollbarData data) {
    if (!scrollController.hasClients || !data.canScroll) return;

    final totalWidth = data.maxScrollExtent + data.viewportDimension;
    final range = (data.trackWidth - data.thumbWidth);
    if (range <= 0) return;

    final deltaOffset =
        details.delta.dx * ((totalWidth - data.viewportDimension) / range);
    final target = (scrollController.offset + deltaOffset).clamp(
      0.0,
      data.maxScrollExtent,
    );

    scrollController.jumpTo(target);
  }

  /// 탭 다운 처리 (썸브 위치로 점프)
  void _onTapDown(TapDownDetails details, _ScrollbarData data) {
    if (!scrollController.hasClients || !data.canScroll) return;

    final totalWidth = data.maxScrollExtent + data.viewportDimension;
    final range = (data.trackWidth - data.thumbWidth);
    if (range <= 0) return;

    final targetThumbLeft = details.localPosition.dx - data.thumbWidth / 2;
    final clampedLeft = targetThumbLeft.clamp(0.0, range);
    final fraction = clampedLeft / range;
    final target = fraction * (totalWidth - data.viewportDimension);

    scrollController.jumpTo(target.clamp(0.0, data.maxScrollExtent));
  }
}

/// 스크롤바 데이터 클래스
class _ScrollbarData {
  final double thumbWidth;
  final double thumbLeft;
  final bool canScroll;
  final double viewportDimension;
  final double maxScrollExtent;
  final double currentOffset;
  final double trackWidth;

  const _ScrollbarData({
    required this.thumbWidth,
    required this.thumbLeft,
    required this.canScroll,
    required this.viewportDimension,
    required this.maxScrollExtent,
    required this.currentOffset,
    required this.trackWidth,
  });
}

/// 화살표 버튼 위젯
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ArrowButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints.tightFor(width: 40, height: 36),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: onPressed != null ? Colors.grey : Colors.grey.shade400,
        size: 25,
      ),
    );
  }
}

/// 스크롤바 트랙 위젯
class _ScrollbarTrack extends StatelessWidget {
  final _ScrollbarData scrollData;
  final Function(DragUpdateDetails, _ScrollbarData) onDragUpdate;
  final Function(TapDownDetails, _ScrollbarData) onTapDown;

  const _ScrollbarTrack({
    required this.scrollData,
    required this.onDragUpdate,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) => onDragUpdate(details, scrollData),
      onTapDown: (details) => onTapDown(details, scrollData),
      child: SizedBox(
        height: 12,
        child: Stack(
          children: [
            // 트랙 배경
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // 썸브
            Positioned(
              left: scrollData.thumbLeft,
              top: 0,
              bottom: 0,
              child: Container(
                width: scrollData.thumbWidth,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
