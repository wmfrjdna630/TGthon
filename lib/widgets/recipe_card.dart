import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String time;
  final int servings;
  final String difficulty;
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
    final progress = ingredientsHave / ingredientsTotal;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 타이틀
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(difficulty, style: const TextStyle(fontSize: 12, color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 시간 및 인원
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(time),
                const SizedBox(width: 12),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('$servings'),
              ],
            ),
            const SizedBox(height: 12),
            // 진행 바
            const Text('Ingredients you have'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 4),
            Text('$ingredientsHave/$ingredientsTotal'),
          ],
        ),
      ),
    );
  }
}
