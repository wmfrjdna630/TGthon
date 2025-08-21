import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe.dart';

/// 레시피 카드 위젯 - 간소화된 버전
/// 레시피 제목과 재료 정보만 표시
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap; // 카드 탭 콜백
  final VoidCallback? onFavorite; // 즐겨찾기 토글 콜백

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavorite,
  });

  /// 기존 인터페이스와의 호환성을 위한 생성자
  factory RecipeCard.legacy({
    required String title,
    required String time,
    required int servings,
    required String difficulty,
    required int ingredientsHave,
    required int ingredientsTotal,
    VoidCallback? onTap,
  }) {
    final recipe = Recipe(
      title: title,
      timeMin: int.tryParse(time.replaceAll('m', '')) ?? 0,
      servings: servings,
      difficulty: difficulty,
      ingredientsHave: ingredientsHave,
      ingredientsTotal: ingredientsTotal,
      tags: [],
    );

    return RecipeCard(recipe: recipe, onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            // 🔥 간소화된 헤더: 제목만 표시 (난이도 배지 제거)
            _RecipeHeader(recipe: recipe),

            const SizedBox(height: 12),

            // 🔥 재료 정보 섹션: 보유/필요 재료 표시
            _IngredientsInfo(recipe: recipe),
          ],
        ),
      ),
    );
  }
}

/// 레시피 헤더 - 제목만 표시 (난이도 제거)
class _RecipeHeader extends StatelessWidget {
  final Recipe recipe;

  const _RecipeHeader({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // 🔥 제목만 표시 (난이도 배지 제거)
    return Text(recipe.title, style: AppTextStyles.cardTitle);
  }
}

/// 재료 정보 섹션 - 보유/필요 재료 개수 표시
class _IngredientsInfo extends StatelessWidget {
  final Recipe recipe;

  const _IngredientsInfo({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 🔥 왼쪽 하단: 보유한 재료
        _IngredientCount(
          label: '보유 재료',
          count: recipe.ingredientsHave,
          color: AppColors.success, // 초록색
        ),

        // 🔥 오른쪽: 필요한 재료
        _IngredientCount(
          label: '필요 재료',
          count: recipe.ingredientsTotal,
          color: AppColors.textSecondary, // 회색
        ),
      ],
    );
  }
}

/// 재료 개수 표시 위젯
class _IngredientCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _IngredientCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmallSecondary),
        const SizedBox(height: 4),
        Text(
          '$count개',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
