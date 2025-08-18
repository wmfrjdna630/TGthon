import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 공통으로 사용되는 파랑색 헤더 위젯
/// 모든 페이지에서 일관된 헤더 디자인을 제공
class BlueHeader extends StatelessWidget {
  final IconData icon; // 헤더 아이콘
  final String title; // 헤더 제목
  final String? subtitle; // 헤더 부제목 (선택사항)
  final Widget? trailing; // 우측에 표시될 위젯 (선택사항)
  final VoidCallback? onTrailingTap; // 우측 위젯 탭 콜백

  const BlueHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTrailingTap,
  });

  /// 팩토리 생성자들 - 자주 사용되는 패턴들

  /// 홈페이지용 헤더
  factory BlueHeader.home({required String userName, required int itemCount}) {
    return BlueHeader(
      icon: Icons.kitchen,
      title: 'My Fridge',
      subtitle: '$itemCount items stored',
    );
  }

  /// 냉장고 페이지용 헤더 (FAB으로 이동하여 + 버튼 제거)
  factory BlueHeader.fridge({
    required int itemCount,
    VoidCallback? onAddPressed, // 사용하지 않지만 호환성을 위해 유지
  }) {
    return BlueHeader(
      icon: Icons.kitchen,
      title: 'My Fridge',
      subtitle: '$itemCount items stored',
      // trailing 제거됨 - FAB으로 대체
    );
  }

  /// 레시피 페이지용 헤더
  factory BlueHeader.recipes({
    required int readyCount,
    required int almostCount,
  }) {
    return BlueHeader(
      icon: Icons.soup_kitchen,
      title: 'Recipes',
      subtitle: '⭐ $readyCount ready to cook • $almostCount almost ready',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 30, 0, 255), // 파랑색 배경
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1976D2), // 진한 파랑 그림자
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
        ],
      ),
    );
  }
}
