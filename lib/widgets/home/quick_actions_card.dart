import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 홈페이지의 빠른 액션 카드 위젯
/// "Add Item", "Scan Receipt" 등의 빠른 액션 버튼들을 제공
class QuickActionsCard extends StatelessWidget {
  final VoidCallback? onAddItemPressed;
  final VoidCallback? onScanReceiptPressed;

  const QuickActionsCard({
    super.key,
    this.onAddItemPressed,
    this.onScanReceiptPressed,
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
          // 섹션 제목
          const Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text('Quick Actions', style: AppTextStyles.sectionTitle),
            ],
          ),

          const SizedBox(height: 12),

          // 액션 버튼들
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add,
                  label: 'Add Item',
                  color: const Color(0xFFF5E6D3),
                  onPressed: onAddItemPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.camera_alt,
                  label: 'Scan Receipt',
                  color: const Color(0xFFF5E6D3),
                  onPressed: onScanReceiptPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 개별 빠른 액션 버튼 위젯
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
