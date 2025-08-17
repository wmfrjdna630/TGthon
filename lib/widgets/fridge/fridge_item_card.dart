import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/fridge_item.dart';

/// 냉장고 아이템을 표시하는 카드 위젯
/// 아이템 정보, 유통기한, 진행률 등을 시각적으로 표현
class FridgeItemCard extends StatelessWidget {
  final FridgeItem item;
  final VoidCallback? onTap; // 카드 탭 콜백
  final VoidCallback? onEdit; // 수정 버튼 콜백
  final VoidCallback? onDelete; // 삭제 버튼 콜백

  const FridgeItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 행: 아이템명 + 카테고리/아이콘
            _ItemHeader(item: item),

            const SizedBox(height: 4),

            // 수량 + 보관위치
            _ItemDetails(item: item),

            const SizedBox(height: 12),

            // 하단 행: 상태 + 남은 일수
            _ItemStatus(item: item),

            const SizedBox(height: 6),

            // 진행률 바
            _ProgressBar(item: item),
          ],
        ),
      ),
    );
  }
}

/// 아이템 헤더 (이름 + 카테고리/아이콘)
class _ItemHeader extends StatelessWidget {
  final FridgeItem item;

  const _ItemHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 아이템명
        Expanded(child: Text(item.name, style: AppTextStyles.cardTitle)),

        // 카테고리 + 아이콘
        Row(
          children: [
            Text(
              item.category,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(item.icon, size: 16, color: Colors.black45),
          ],
        ),
      ],
    );
  }
}

/// 아이템 세부정보 (수량 + 보관위치)
class _ItemDetails extends StatelessWidget {
  final FridgeItem item;

  const _ItemDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${item.amount} · ${item.location}',
      style: AppTextStyles.bodySecondary,
    );
  }
}

/// 아이템 상태 (상태 텍스트 + 남은 일수)
class _ItemStatus extends StatelessWidget {
  final FridgeItem item;

  const _ItemStatus({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 상태 텍스트 (색상 포함)
        Text(
          item.status,
          style: TextStyle(
            color: item.statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        // 남은 일수
        Text('${item.daysLeft}d left', style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

/// 진행률 표시 바
class _ProgressBar extends StatelessWidget {
  final FridgeItem item;

  const _ProgressBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: item.progressRatio,
        backgroundColor: AppColors.progressInactive,
        valueColor: AlwaysStoppedAnimation<Color>(item.statusColor),
        minHeight: 8,
      ),
    );
  }
}
