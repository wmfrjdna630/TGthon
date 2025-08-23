// lib/widgets/home/expiry_indicator_bar.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/fridge_item.dart';

/// 유통기한 상태를 표시하는 상단 인디케이터 바
/// 위험/주의/안전 아이템 개수를 시각적으로 보여줌
///
/// 🔴 유통기한 기준:
/// - 위험(X 아이콘): 7일 이하
/// - 주의(! 아이콘): 8일 ~ 29일
/// - 안전(✓ 아이콘): 30일 이상
class ExpiryIndicatorBar extends StatelessWidget {
  final List<FridgeItem> fridgeItems;

  const ExpiryIndicatorBar({super.key, required this.fridgeItems});

  @override
  Widget build(BuildContext context) {
    // 🔴 핵심: 올바른 유통기한 기준으로 카운트 계산
    // AppColors의 기준과 동일하게 맞춤
    final dangerCount = fridgeItems
        .where((item) => item.daysLeft <= 7)
        .length; // 7일 이하
    final warningCount = fridgeItems
        .where((item) => item.daysLeft > 7 && item.daysLeft < 30) // 8-29일
        .length;
    final safeCount = fridgeItems
        .where((item) => item.daysLeft >= 30)
        .length; // 30일 이상

    // 디버깅용 로그 (필요시 주석 해제)
    // print('📊 ExpiryIndicatorBar 카운트 - 위험: $dangerCount, 주의: $warningCount, 안전: $safeCount');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 위험 인디케이터 (X 아이콘, 빨간색)
          _RiskIndicator(
            icon: Icons.dangerous, // X 모양 아이콘
            count: dangerCount.toString(),
            color: AppColors.danger, // 빨간색
            //label: '위험',
          ),
          // 주의 인디케이터 (! 아이콘, 주황색)
          _RiskIndicator(
            icon: Icons.warning, // ! 모양 아이콘
            count: warningCount.toString(),
            color: AppColors.warning, // 주황색
            //label: '주의',
          ),
          // 안전 인디케이터 (✓ 아이콘, 초록색)
          _RiskIndicator(
            icon: Icons.check_circle, // ✓ 모양 아이콘
            count: safeCount.toString(),
            color: AppColors.success, // 초록색
            //label: '안전',
          ),
        ],
      ),
    );
  }
}

/// 개별 위험도 인디케이터 위젯
/// 아이콘과 카운트를 표시
class _RiskIndicator extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color color;
  //final String label;

  const _RiskIndicator({
    required this.icon,
    required this.count,
    required this.color,
    //required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 표시
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            // 카운트 표시
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 라벨은 주석 처리됨 (필요시 활성화 가능)
        // Text(
        //   label,
        //   style: TextStyle(
        //     fontSize: 11,
        //     color: color,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ],
    );
  }
}
