import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 공통으로 사용되는 초록색 헤더 위젯
/// 모든 페이지에서 일관된 헤더 디자인을 제공
class GreenHeader extends StatelessWidget {
  final IconData icon; // 헤더 아이콘
  final String title; // 헤더 제목
  final String? subtitle; // 헤더 부제목 (선택사항)
  final Widget? trailing; // 우측에 표시될 위젯 (선택사항)
  final VoidCallback? onTrailingTap; // 우측 위젯 탭 콜백

  const GreenHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTrailingTap,
  });

  /// 팩토리 생성자들 - 자주 사용되는 패턴들

  /// 홈페이지용 헤더
  factory GreenHeader.home({required String userName, required int itemCount}) {
    return GreenHeader(
      icon: Icons.kitchen,
      title: 'My Fridge',
      subtitle: '$itemCount items stored',
    );
  }

  /// 냉장고 페이지용 헤더 (+버튼 포함)
  factory GreenHeader.fridge({
    required int itemCount,
    VoidCallback? onAddPressed,
  }) {
    return GreenHeader(
      icon: Icons.kitchen,
      title: 'My Fridge',
      subtitle: '$itemCount items stored',
      trailing: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: const Text(
          '+',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      onTrailingTap: onAddPressed,
    );
  }

  /// 레시피 페이지용 헤더
  factory GreenHeader.recipes({
    required int readyCount,
    required int almostCount,
  }) {
    return GreenHeader(
      icon: Icons.soup_kitchen,
      title: 'Recipes',
      subtitle: null, // 커스텀 서브타이틀을 위해 null
      trailing: _RecipeStatusLine(
        readyCount: readyCount,
        almostCount: almostCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 중앙 정렬된 메인 콘텐츠
          _buildMainContent(),

          // 우측 위젯 (있는 경우)
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(onTap: onTrailingTap, child: trailing!),
            ),
        ],
      ),
    );
  }

  /// 메인 콘텐츠 (아이콘 + 제목 + 부제목) 빌드
  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 아이콘 + 제목 행
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.pageTitle),
            ],
          ),

          // 부제목 (있는 경우)
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageSubtitle,
            ),
          ],

          // 레시피 페이지의 경우 특별한 상태 라인 표시
          if (title == 'Recipes' && trailing is _RecipeStatusLine) ...[
            const SizedBox(height: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// 레시피 페이지 헤더용 상태 라인 위젯
class _RecipeStatusLine extends StatelessWidget {
  final int readyCount;
  final int almostCount;

  const _RecipeStatusLine({
    required this.readyCount,
    required this.almostCount,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.star_border, size: 16, color: Colors.white),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: '$readyCount ready to cook',
            style: const TextStyle(color: Colors.white),
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: 12),
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _Dot(color: Color(0xFFF5A623)),
          ),
          TextSpan(
            text: ' $almostCount almost ready',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 작은 원형 도트 위젯
class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
