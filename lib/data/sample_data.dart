// lib/data/sample_data.dart
import '../models/fridge_item.dart';
import '../models/menu_rec.dart';
import '../models/recipe.dart';
import '../models/unified_recipe.dart';

/// 앱에서 사용하는 모든 샘플 데이터를 관리하는 클래스
/// 이제 'UnifiedRecipe' 단일 소스를 기반으로
/// - 홈: MenuRec 리스트
/// - 레시피: Recipe 리스트
/// 를 파생하여 사용한다.
class SampleData {
  SampleData._();

  // ================== 냉장고 아이템(그대로) ==================
  static final List<FridgeItem> fridgeItems = [
    FridgeItem.fromSampleData(
      name: '계란',
      amount: '6개',
      category: '유제품',
      location: 'Fridge',
      daysLeft: 2,
      totalDays: 14,
    ),
    FridgeItem.fromSampleData(
      name: '우유',
      amount: '1L',
      category: '유제품',
      location: 'Fridge',
      daysLeft: 3,
      totalDays: 7,
    ),
    FridgeItem.fromSampleData(
      name: 'Chicken Breast',
      amount: '500g',
      category: 'Meat',
      location: 'Fridge',
      daysLeft: 1,
      totalDays: 3,
    ),
    FridgeItem.fromSampleData(
      name: '버터',
      amount: '200g',
      category: '유제품',
      location: 'Fridge',
      daysLeft: 5,
      totalDays: 30,
    ),
    FridgeItem.fromSampleData(
      name: 'Tomatoes',
      amount: '6개',
      category: 'Vegetables',
      location: 'Fridge',
      daysLeft: 2,
      totalDays: 7,
    ),
    FridgeItem.fromSampleData(
      name: '김치',
      amount: '500g',
      category: '채소',
      location: 'Fridge',
      daysLeft: 10,
      totalDays: 30,
    ),
    FridgeItem.fromSampleData(
      name: '양파',
      amount: '3개',
      category: '채소',
      location: 'Pantry',
      daysLeft: 15,
      totalDays: 30,
    ),
    FridgeItem.fromSampleData(
      name: '마늘',
      amount: '1통',
      category: '채소',
      location: 'Pantry',
      daysLeft: 20,
      totalDays: 60,
    ),
    FridgeItem.fromSampleData(
      name: '치즈',
      amount: '300g',
      category: '유제품',
      location: 'Fridge',
      daysLeft: 80,
      totalDays: 45,
    ),
    FridgeItem.fromSampleData(
      name: '감자',
      amount: '5개',
      category: '채소',
      location: 'Pantry',
      daysLeft: 28,
      totalDays: 60,
    ),
    FridgeItem.fromSampleData(
      name: 'Frozen Peas',
      amount: '300g',
      category: 'Vegetables',
      location: 'Freezer',
      daysLeft: 30,
      totalDays: 90,
    ),
    FridgeItem.fromSampleData(
      name: 'Pasta',
      amount: '500g',
      category: 'Grains',
      location: 'Pantry',
      daysLeft: 180,
      totalDays: 365,
    ),
    FridgeItem.fromSampleData(
      name: 'Ice Cream',
      amount: '500ml',
      category: 'Dessert',
      location: 'Freezer',
      daysLeft: 45,
      totalDays: 180,
    ),
    FridgeItem.fromSampleData(
      name: '올리브오일',
      amount: '250ml',
      category: '조미료',
      location: 'Pantry',
      daysLeft: 120,
      totalDays: 365,
    ),
    FridgeItem.fromSampleData(
      name: '쌀',
      amount: '2kg',
      category: '곡류',
      location: 'Pantry',
      daysLeft: 300,
      totalDays: 365,
    ),
  ];

  static List<FridgeItem> get timelineItems => fridgeItems;

  // ================== 단일 소스: UnifiedRecipe ==================
  static final List<UnifiedRecipe> unifiedRecipes = [
    // 한식
    UnifiedRecipe(
      title: '된장찌개',
      cuisine: '한식',
      timeMin: 35,
      servings: 2,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 6,
      tags: ['soup', 'healthy'],
      needMessage: '애호박, 된장 재료가 꼭 필요해요!',
      goodMessage: '치킨스톡 재료가 있으면 더 좋아요!',
      minDaysLeft: 1,
      frequency: 2,
      favorite: false,
      hasAllRequired: false,
    ),
    UnifiedRecipe(
      title: '간장계란밥',
      cuisine: '한식',
      timeMin: 8,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 4,
      tags: ['quick'],
      needMessage: '',
      goodMessage: '참기름 재료가 있으면 더 좋아요!',
      minDaysLeft: 2,
      frequency: 5,
      favorite: true,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '김치볶음밥',
      cuisine: '한식',
      timeMin: 18,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 4,
      ingredientsTotal: 5,
      tags: ['quick'],
      needMessage: '',
      goodMessage: '베이컨, 햄이 있으면 더 맛있어요!',
      minDaysLeft: 10,
      frequency: 4,
      favorite: true,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '버터스크램블',
      cuisine: '양식',
      timeMin: 10,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 4,
      tags: ['quick', 'egg'],
      needMessage: '',
      goodMessage: '체다치즈, 파슬리가 있으면 완벽해요!',
      minDaysLeft: 2,
      frequency: 3,
      favorite: false,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '양파볶음',
      cuisine: '한식',
      timeMin: 12,
      servings: 2,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 4,
      tags: ['quick', 'vegan'],
      needMessage: '',
      goodMessage: '간장, 설탕이 있으면 더 달콤해요!',
      minDaysLeft: 15,
      frequency: 2,
      favorite: false,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '마늘볶음밥',
      cuisine: '한식',
      timeMin: 15,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 5,
      tags: ['quick'],
      needMessage: '',
      goodMessage: '햄, 당근이 있으면 더 푸짐해요!',
      minDaysLeft: 20,
      frequency: 3,
      favorite: false,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '알리오 파스타',
      cuisine: '양식',
      timeMin: 20,
      servings: 1,
      difficulty: 'medium',
      ingredientsHave: 4,
      ingredientsTotal: 6,
      tags: ['pasta', 'quick'],
      needMessage: '파스타면, 올리브오일이 꼭 필요해요!',
      goodMessage: '파슬리, 치즈가 있으면 더 좋아요!',
      minDaysLeft: 120,
      frequency: 3,
      favorite: true,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '치즈토스트',
      cuisine: '간식',
      timeMin: 7,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 2,
      ingredientsTotal: 4,
      tags: ['snack', 'quick'],
      needMessage: '식빵이 꼭 필요해요!',
      goodMessage: '토마토, 햄이 있으면 더 풍성해요!',
      minDaysLeft: 25,
      frequency: 4,
      favorite: false,
      hasAllRequired: false,
    ),
    UnifiedRecipe(
      title: '감자볶음',
      cuisine: '한식',
      timeMin: 14,
      servings: 2,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 5,
      tags: ['quick', 'vegan'],
      needMessage: '',
      goodMessage: '양파, 당근이 있으면 더 맛있어요!',
      minDaysLeft: 28,
      frequency: 2,
      favorite: false,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '스크램블 에그',
      cuisine: '양식',
      timeMin: 8,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 3,
      tags: ['quick', 'egg', 'vegetarian'],
      needMessage: '',
      goodMessage: '치즈, 허브가 있으면 고급스러워요!',
      minDaysLeft: 2,
      frequency: 6,
      favorite: true,
      hasAllRequired: true,
    ),
    UnifiedRecipe(
      title: '우유 시리얼',
      cuisine: '간식',
      timeMin: 3,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 1,
      ingredientsTotal: 2,
      tags: ['snack', 'quick'],
      needMessage: '시리얼이 꼭 필요해요!',
      goodMessage: '과일, 견과류가 있으면 영양만점!',
      minDaysLeft: 3,
      frequency: 7,
      favorite: false,
      hasAllRequired: false,
    ),
    UnifiedRecipe(
      title: '계란후라이',
      cuisine: '양식',
      timeMin: 5,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 1,
      ingredientsTotal: 1,
      tags: ['quick', 'egg'],
      needMessage: '',
      goodMessage: '토스트, 샐러드가 있으면 완벽한 한 끼!',
      minDaysLeft: 2,
      frequency: 8,
      favorite: true,
      hasAllRequired: true,
    ),
  ];

  // 파생: 홈에서 쓰는 메뉴 추천
  static List<MenuRec> get menuRecommendations =>
      unifiedRecipes.map((u) => u.asMenuRec()).toList();

  // 파생: 레시피 페이지에서 쓰는 레시피
  static List<Recipe> get recipes =>
      unifiedRecipes.map((u) => u.asRecipe()).toList();

  // ===== 통계/유틸 (기존 유지 또는 경로만 통일) =====
  static Map<String, int> get fridgeItemCounts {
    final counts = <String, int>{'danger': 0, 'warning': 0, 'safe': 0};
    for (final item in fridgeItems) {
      if (item.daysLeft <= 7) {
        counts['danger'] = (counts['danger'] ?? 0) + 1;
      } else if (item.daysLeft <= 28) {
        counts['warning'] = (counts['warning'] ?? 0) + 1;
      } else {
        counts['safe'] = (counts['safe'] ?? 0) + 1;
      }
    }
    return counts;
  }

  static Map<String, int> get menuStats {
    final list = menuRecommendations;
    final available = list.where((m) => m.hasAllRequired).length;
    final total = list.length;
    final urgent = list.where((m) => m.minDaysLeft <= 7).length;
    return {
      'available': available,
      'total': total,
      'urgent': urgent,
      'missing': total - available,
    };
  }

  static String get userName => '공육공육공';

  static List<FridgeItem> getFridgeItemsByLocation(String location) {
    if (location == 'All') return fridgeItems;
    return fridgeItems.where((item) => item.location == location).toList();
  }

  static List<FridgeItem> getFridgeItemsByTimeFilter(int maxDays) {
    return fridgeItems.where((item) => item.daysLeft <= maxDays).toList();
  }

  /// 태그 포함 여부로 단순 필터
  static List<Recipe> getRecipesByTag(String tag) {
    return recipes.where((r) => r.tags.contains(tag)).toList();
  }
}
