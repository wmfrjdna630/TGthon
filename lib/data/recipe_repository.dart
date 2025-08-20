// lib/data/recipe_repository.dart
import 'remote/recipe_api.dart';
import '../models/api/foodsafety_recipe.dart';
import '../models/unified_recipe.dart';
import '../models/recipe.dart';
import '../models/menu_rec.dart';
import 'sample_data.dart';

class RecipeRepository {
  final RecipeApi api;

  RecipeRepository({required this.api});

  /// UI 필터를 API 파라미터로 매핑하여 검색
  Future<List<UnifiedRecipe>> searchUnified({
    String? keyword, // RCP_NM
    String? dishType, // RCP_PAT2
    String? include, // RCP_PARTS_DTLS
    int page = 1,
    int pageSize = 20,
  }) async {
    final start = (page - 1) * pageSize + 1;
    final end = page * pageSize;

    final raw = await api.fetch(
      startIdx: start,
      endIdx: end,
      menuName: keyword,
      dishType: dishType,
      includeParts: include,
      json: true,
    );

    // COOKRCP01 > row 배열 꺼내기
    final root = raw['COOKRCP01'] as Map<String, dynamic>? ?? {};
    final rows = root['row'] as List<dynamic>? ?? const [];

    final owned = SampleData.fridgeItems
        .map((e) => e.name.trim().toLowerCase())
        .toSet();

    final list = rows
        .whereType<Map<String, dynamic>>()
        .map((j) => FoodSafetyRecipeDto.fromJson(j).toUnified(owned: owned))
        .toList();

    return list;
  }

  Future<List<Recipe>> searchRecipes({
    String? keyword,
    String? dishType,
    String? include,
    int page = 1,
    int pageSize = 20,
  }) async {
    final unified = await searchUnified(
      keyword: keyword,
      dishType: dishType,
      include: include,
      page: page,
      pageSize: pageSize,
    );
    return unified.map((u) => u.asRecipe()).toList();
  }

  Future<List<MenuRec>> searchMenus({
    String? keyword,
    String? dishType,
    String? include,
    int page = 1,
    int pageSize = 20,
  }) async {
    final unified = await searchUnified(
      keyword: keyword,
      dishType: dishType,
      include: include,
      page: page,
      pageSize: pageSize,
    );
    return unified.map((u) => u.asMenuRec()).toList();
  }
}
