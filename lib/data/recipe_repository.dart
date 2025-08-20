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

  /// 단일 페이지 조회 (기존 로직 유지)
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

  // =========================
  // 🔥 여기부터 "전부 불러오기" 유틸
  // =========================

  /// API 페이지를 끝까지 돌며 전부 가져오는 헬퍼
  /// - 안전장치: maxPages / maxTotal
  Future<List<UnifiedRecipe>> fetchAllUnified({
    String? keyword,
    String? dishType,
    String? include,
    int pageSize = 100, // 크게 요청해서 왕복 수를 줄임
    int maxPages = 200, // 비정상 루프 방지
    int maxTotal = 20000, // 과도한 수집 방지
  }) async {
    final List<UnifiedRecipe> all = [];
    var page = 1;

    while (true) {
      final batch = await searchUnified(
        keyword: keyword,
        dishType: dishType,
        include: include,
        page: page,
        pageSize: pageSize,
      );
      all.addAll(batch);

      final reachedEnd = batch.length < pageSize;
      final reachedLimit = page >= maxPages || all.length >= maxTotal;
      if (reachedEnd || reachedLimit) break;

      page += 1;
    }
    return all;
  }

  Future<List<Recipe>> fetchAllRecipes({
    String? keyword,
    String? dishType,
    String? include,
    int pageSize = 100,
    int maxPages = 200,
    int maxTotal = 20000,
  }) async {
    final unified = await fetchAllUnified(
      keyword: keyword,
      dishType: dishType,
      include: include,
      pageSize: pageSize,
      maxPages: maxPages,
      maxTotal: maxTotal,
    );
    return unified.map((u) => u.asRecipe()).toList();
  }

  Future<List<MenuRec>> fetchAllMenus({
    String? keyword,
    String? dishType,
    String? include,
    int pageSize = 100,
    int maxPages = 200,
    int maxTotal = 20000,
  }) async {
    final unified = await fetchAllUnified(
      keyword: keyword,
      dishType: dishType,
      include: include,
      pageSize: pageSize,
      maxPages: maxPages,
      maxTotal: maxTotal,
    );
    return unified.map((u) => u.asMenuRec()).toList();
  }
}
