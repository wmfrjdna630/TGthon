import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/fridge_item.dart';

/// 유통기한 상태를 표시하는 상단 인디케이터 바
/// 위험/주의/안전 아이템 개수를 시각적으로 보여줌
class ExpiryIndicatorBar extends StatelessWidget {
  final List<FridgeItem> fridgeItems;

  const ExpiryIndicatorBar({super.key, required this.fridgeItems});

  @override
  Widget build(BuildContext context) {
    // 위험/주의/안전 개수 계산
    final dangerCount = fridgeItems.where((item) => item.daysLeft <= 3).length;
    final warningCount = fridgeItems
        .where((item) => item.daysLeft > 3 && item.daysLeft <= 7)
        .length;
    final safeCount = fridgeItems.where((item) => item.daysLeft > 7).length;

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
          _RiskIndicator(
            icon: Icons.dangerous,
            count: dangerCount.toString(),
            color: AppColors.danger,
            //label: '위험',
          ),
          _RiskIndicator(
            icon: Icons.warning,
            count: warningCount.toString(),
            color: AppColors.warning,
            //label: '주의',
          ),
          _RiskIndicator(
            icon: Icons.check_circle,
            count: safeCount.toString(),
            color: AppColors.success,
            //label: '안전',
          ),
        ],
      ),
    );
  }
}

/// 개별 위험도 인디케이터 위젯
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
            Icon(icon, color: color, size: 22), // ✅ 동그라미 제거, 아이콘만
            const SizedBox(width: 6),
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
