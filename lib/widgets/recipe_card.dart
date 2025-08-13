import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String time; // ex) "25m"
  final int servings; // ex) 2
  final String difficulty; // ex) "easy" | "medium"
  final int ingredientsHave;
  final int ingredientsTotal;

  const RecipeCard({
    super.key,
    required this.title,
    required this.time,
    required this.servings,
    required this.difficulty,
    required this.ingredientsHave,
    required this.ingredientsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (ingredientsTotal == 0)
        ? 0
        : (ingredientsHave / ingredientsTotal).clamp(0, 1);

    return Container(
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
          // 제목 + 난이도 배지
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  difficulty,
                  style: const TextStyle(
                    color: Color(0xFF34C965),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 메타 정보
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.black54),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 12),
              const Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 4),
              Text('$servings', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'Ingredients you have',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 6),

          // 진행바 + 비율
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF34C965),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$ingredientsHave/$ingredientsTotal',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
