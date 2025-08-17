import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/menu_rec.dart';
import '../../screens/home/home_page.dart'; // SortMode enum 사용

/// 홈페이지의 메뉴 추천 섹션 위젯
/// 사용자가 보유한 재료를 기반으로 만들 수 있는 메뉴들을 추천
class MenuRecommendations extends StatelessWidget {
  final List<MenuRec> menuRecommendations; // 추천 메뉴 리스트
  final SortMode currentSortMode; // 현재 정렬 모드
  final ValueChanged<SortMode> onSortModeChanged; // 정렬 모드 변경 콜백
  final Function(MenuRec)? onMenuTapped; // 메뉴 클릭 콜백 (새로 추가)
  final Function(MenuRec)? onFavoriteToggled; // 즐겨찾기 토글 콜백 (새로 추가)

  const MenuRecommendations({
    super.key,
    required this.menuRecommendations,
    required this.currentSortMode,
    required this.onSortModeChanged,
    this.onMenuTapped, // 메뉴 클릭 핸들러
    this.onFavoriteToggled, // 즐겨찾기 토글 핸들러
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

          // 메뉴 카드들 (클릭 가능하도록 수정)
          ...menuRecommendations.map(
            (menu) => _MenuCard(
              menu: menu,
              onTap: () => onMenuTapped?.call(menu), // 메뉴 클릭 콜백
              onFavoriteToggle: () => onFavoriteToggled?.call(menu), // 즐겨찾기 콜백
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
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.blue) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.blue[800] : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 개별 메뉴 추천 카드 (클릭 가능하도록 수정)
class _MenuCard extends StatelessWidget {
  final MenuRec menu;
  final VoidCallback? onTap; // 메뉴 전체 클릭 콜백
  final VoidCallback? onFavoriteToggle; // 즐겨찾기 토글 콜백

  const _MenuCard({required this.menu, this.onTap, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // 메뉴 카드 전체를 클릭 가능하게 만들기
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: menu.hasAllRequired
                  ? AppColors.menuAvailable
                  : AppColors.menuMissing,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: menu.hasAllRequired
                    ? AppColors.menuAvailableBorder
                    : AppColors.menuMissingBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 메뉴 제목 + 즐겨찾기 버튼
                Row(
                  children: [
                    // 메뉴 제목 (확장하여 공간 차지)
                    Expanded(
                      child: Text(menu.title, style: AppTextStyles.menuTitle),
                    ),

                    // 즐겨찾기 하트 버튼 (클릭 가능)
                    _FavoriteButton(
                      isFavorite: menu.favorite,
                      onToggle: onFavoriteToggle,
                    ),
                  ],
                ),

                // 필수 재료 메시지 (부족한 경우)
                if (menu.needMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _MessageRow(
                    icon: Icons.warning_amber,
                    message: menu.needMessage,
                    color: menu.hasAllRequired ? Colors.green : Colors.orange,
                  ),
                ],

                // 선택 재료 메시지 (있으면 더 좋은 재료)
                if (menu.goodMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _MessageRow(
                    icon: Icons.check_circle,
                    message: menu.goodMessage,
                    color: Colors.green,
                  ),
                ],
              ],
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
        // 하트 버튼만 따로 클릭 가능
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8), // 클릭 영역 확대를 위한 패딩
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
    // MaterialColor인 경우 shade700 사용
    if (color is MaterialColor) {
      return color.shade700;
    }

    // 일반 Color인 경우 HSL을 이용해 어둡게 만들기
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}
