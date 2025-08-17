import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe.dart';

/// 레시피 카드 위젯
/// 레시피 정보, 난이도, 조리시간, 재료 진행률 등을 표시
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
            // 상단: 제목 + 난이도 배지
            _RecipeHeader(recipe: recipe),

            const SizedBox(height: 8),

            // 메타 정보: 시간 + 인분
            _RecipeMetaInfo(recipe: recipe),

            const SizedBox(height: 10),

            // 재료 진행률 섹션
            _IngredientsProgress(recipe: recipe),
          ],
        ),
      ),
    );
  }
}

/// 레시피 헤더 (제목 + 난이도)
class _RecipeHeader extends StatelessWidget {
  final Recipe recipe;

  const _RecipeHeader({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 레시피 제목
        Expanded(child: Text(recipe.title, style: AppTextStyles.cardTitle)),

        // 난이도 배지
        _DifficultyBadge(difficulty: recipe.difficulty),
      ],
    );
  }
}

/// 난이도 배지
class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.filterSelected,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(difficulty, style: AppTextStyles.recipeDifficulty),
    );
  }
}

/// 레시피 메타 정보 (시간 + 인분)
class _RecipeMetaInfo extends StatelessWidget {
  final Recipe recipe;

  const _RecipeMetaInfo({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 조리 시간
        const Icon(Icons.access_time, size: 16, color: Colors.black54),
        const SizedBox(width: 4),
        Text(recipe.formattedTime, style: AppTextStyles.recipeMeta),

        const SizedBox(width: 12),

        // 인분
        const Icon(Icons.people_alt_outlined, size: 16, color: Colors.black54),
        const SizedBox(width: 4),
        Text(recipe.formattedServings, style: AppTextStyles.recipeMeta),
      ],
    );
  }
}

/// 재료 진행률 섹션
class _IngredientsProgress extends StatelessWidget {
  final Recipe recipe;

  const _IngredientsProgress({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        const Text('Ingredients you have', style: AppTextStyles.bodySecondary),

        const SizedBox(height: 6),

        // 진행률 바 + 비율
        Row(
          children: [
            // 진행률 바
            Expanded(child: _ProgressBar(progress: recipe.ingredientProgress)),

            const SizedBox(width: 8),

            // 비율 텍스트
            Text(
              '${recipe.ingredientsHave}/${recipe.ingredientsTotal}',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ],
    );
  }
}

/// 진행률 바
class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppColors.progressBackground,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        minHeight: 8,
      ),
    );
  }
}
