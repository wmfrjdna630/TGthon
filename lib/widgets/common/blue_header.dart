import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

class BlueHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;

  // 👉 높이(여백) 조절용 옵션 추가: 기본을 슬림으로
  final double verticalPadding;
  final double horizontalPadding;

  const BlueHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTrailingTap,
    this.verticalPadding = 14, // ⬅️ 기존 24 → 14로 축소
    this.horizontalPadding = 20, // ⬅️ 기존 24 → 20로 축소
  });

  factory BlueHeader.home({required String userName, required int itemCount}) {
    return BlueHeader(
      icon: Icons.kitchen,
      title: 'My Fridge',
      subtitle: '$itemCount items stored',
    );
  }

  factory BlueHeader.fridge({
    required int itemCount,
    VoidCallback? onAddPressed,
  }) {
    return BlueHeader(
      icon: Icons.kitchen,
      title: 'My Fridge',
      subtitle: '$itemCount items stored',
    );
  }

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
      // ⬇️ 슬림 패딩 적용
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 30, 0, 255),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          // 살짝 과했던 그림자 톤도 부드럽게
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildMainContent(),
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(onTap: onTrailingTap, child: trailing!),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 6), // 살짝 더 촘촘하게
              Text(title, style: AppTextStyles.pageTitle),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3), // 부제목 간격도 살짝 축소
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
