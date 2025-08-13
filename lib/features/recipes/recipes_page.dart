import 'package:flutter/material.dart';
import '../../widgets/recipe_card.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade400,
        title: const Text(
          'Recipes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '⭐ 0 ready to cook   🔴 2 almost ready',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.filter_list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 필터 바
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: const [
                FilterChip(label: Text('Can make now (0)'), onSelected: _noop),
                SizedBox(width: 8),
                FilterChip(label: Text('Almost ready (2)'), onSelected: _noop),
                SizedBox(width: 8),
                FilterChip(label: Text('Quick meals'), onSelected: _noop),
                SizedBox(width: 8),
                FilterChip(label: Text('Vegetarian'), onSelected: _noop),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 레시피 리스트
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12.0),
              children: const [
                RecipeCard(
                  title: 'Fresh Garden Salad',
                  time: '10m',
                  servings: 1,
                  difficulty: 'easy',
                  ingredientsHave: 3,
                  ingredientsTotal: 4,
                ),
                RecipeCard(
                  title: 'Vegetable Soup',
                  time: '45m',
                  servings: 4,
                  difficulty: 'easy',
                  ingredientsHave: 5,
                  ingredientsTotal: 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _noop(bool _) {}