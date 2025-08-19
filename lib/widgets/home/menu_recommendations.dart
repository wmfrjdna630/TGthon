import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/menu_rec.dart';
import '../../screens/home/home_page.dart'; // SortMode enum 사용

/// 홈페이지의 메뉴 추천 섹션 위젯
class MenuRecommendations extends StatelessWidget {
  final List<MenuRec> menuRecommendations; // 추천 메뉴 리스트
  final SortMode currentSortMode; // 현재 정렬 모드
  final ValueChanged<SortMode> onSortModeChanged; // 정렬 모드 변경 콜백
  final Function(MenuRec)? onMenuTapped; // 메뉴 클릭 콜백
  final Function(MenuRec)? onFavoriteToggled; // 즐겨찾기 토글 콜백

  const MenuRecommendations({
    super.key,
    required this.menuRecommendations,
    required this.currentSortMode,
    required this.onSortModeChanged,
    this.onMenuTapped,
    this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (제목 + 정렬 칩들)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('메뉴 추천', style: AppTextStyles.sectionTitle),
              _SortChips(
                currentSortMode: currentSortMode,
                onSortModeChanged: onSortModeChanged,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 메뉴 카드들
          ...menuRecommendations.map(
            (menu) => _MenuCard(
              menu: menu,
              onTap: () => onMenuTapped?.call(menu),
              onFavoriteToggle: () => onFavoriteToggled?.call(menu),
            ),
          ),
        ],
      ),
    );
  }
}

/// 정렬 모드 선택 칩들
class _SortChips extends StatelessWidget {
  final SortMode currentSortMode;
  final ValueChanged<SortMode> onSortModeChanged;

  const _SortChips({
    required this.currentSortMode,
    required this.onSortModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SortChip(
          label: '유통기한순',
          mode: SortMode.expiry,
          isSelected: currentSortMode == SortMode.expiry,
          onTap: () => onSortModeChanged(SortMode.expiry),
        ),
        const SizedBox(width: 4),
        _SortChip(
          label: '빈도순',
          mode: SortMode.frequency,
          isSelected: currentSortMode == SortMode.frequency,
          onTap: () => onSortModeChanged(SortMode.frequency),
        ),
        const SizedBox(width: 4),
        _SortChip(
          label: '즐겨찾는순',
          mode: SortMode.favorite,
          isSelected: currentSortMode == SortMode.favorite,
          onTap: () => onSortModeChanged(SortMode.favorite),
        ),
      ],
    );
  }
}

/// 개별 정렬 칩
class _SortChip extends StatelessWidget {
  final String label;
  final SortMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 30, 0, 255)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color.fromARGB(255, 30, 0, 255))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 개별 메뉴 추천 카드
/// - Hover / Focus: 살짝 확대 + 그림자 강화
/// - Press(터치/클릭 중): 살짝 축소
class _MenuCard extends StatefulWidget {
  final MenuRec menu;
  final VoidCallback? onTap; // 메뉴 전체 클릭 콜백
  final VoidCallback? onFavoriteToggle; // 즐겨찾기 토글 콜백

  const _MenuCard({required this.menu, this.onTap, this.onFavoriteToggle});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  static const _animDuration = Duration(milliseconds: 130);

  @override
  Widget build(BuildContext context) {
    final isEmphasized = _hovered || _focused;
    final scale = _pressed ? 0.985 : (isEmphasized ? 1.015 : 1.0);

    final baseBorderColor = widget.menu.hasAllRequired
        ? AppColors.menuAvailableBorder
        : AppColors.menuMissingBorder;

    final borderColor = isEmphasized
        ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.75)
        : baseBorderColor;

    final List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(isEmphasized ? 0.14 : 0.06),
        blurRadius: isEmphasized ? 14 : 8,
        offset: Offset(0, isEmphasized ? 6 : 4),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: AnimatedContainer(
          duration: _animDuration,
          curve: Curves.easeOut,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()..scale(scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.menu.hasAllRequired
                      ? AppColors.menuAvailable
                      : AppColors.menuMissing,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 메뉴 제목 + 즐겨찾기 버튼
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.menu.title,
                            style: AppTextStyles.menuTitle,
                          ),
                        ),
                        _FavoriteButton(
                          isFavorite: widget.menu.favorite,
                          onToggle: widget.onFavoriteToggle,
                        ),
                      ],
                    ),

                    // ====== 메시지 영역 수정 시작 ======
                    // 필수 재료 메시지: 항상 주황색, 한 번만 표시
                    if (widget.menu.needMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _MessageRow(
                        icon: Icons.warning_amber_rounded,
                        message: widget.menu.needMessage,
                        color: Colors.orange,
                      ),
                    ],

                    // 선택 재료 메시지: 초록색, 정상 노출
                    if (widget.menu.goodMessage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _MessageRow(
                        icon: Icons.check_circle_rounded,
                        message: widget.menu.goodMessage,
                        color: Colors.green,
                      ),
                    ],
                    // ====== 메시지 영역 수정 끝 ======
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 즐겨찾기 하트 버튼 위젯
class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onToggle;

  const _FavoriteButton({required this.isFavorite, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// 메시지 행 (아이콘 + 텍스트)
class _MessageRow extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _MessageRow({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.menuDescription(_getDarkerColor(color)),
          ),
        ),
      ],
    );
  }

  /// 색상을 더 어둡게 만드는 헬퍼 메서드
  Color _getDarkerColor(Color color) {
    if (color is MaterialColor) return color.shade700;
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}
