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

  /// 레시피 페이지용 헤더 (중복 제거됨)
  /// readyCount와 almostCount를 subtitle로 설정하여 중복 방지
  factory GreenHeader.recipes({
    required int readyCount,
    required int almostCount,
  }) {
    return GreenHeader(
      icon: Icons.soup_kitchen,
      title: 'Recipes',
      // 기존에 _RecipeStatusLine을 trailing으로 설정했던 것을 제거하고
      // 대신 간단한 텍스트 subtitle로 변경하여 중복 방지
      subtitle: '⭐ $readyCount ready to cook • $almostCount almost ready',
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
  /// 레시피 페이지의 중복 표시 문제를 해결하기 위해 조건문 제거
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

          // 기존에 있던 레시피 페이지 특별 처리 부분을 제거하여 중복 방지
          // if (title == 'Recipes' && trailing is _RecipeStatusLine) 부분 삭제됨
        ],
      ),
    );
  }
}

// _RecipeStatusLine과 _Dot 클래스들은 더 이상 사용되지 않으므로 제거됨
