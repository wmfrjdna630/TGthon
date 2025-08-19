import '../models/fridge_item.dart';
import '../models/menu_rec.dart';
import '../models/recipe.dart';

/// 앱에서 사용하는 모든 샘플 데이터를 관리하는 클래스
/// 개발 및 테스트 목적으로 사용되는 더미 데이터들
/// 타임라인과 냉장고 페이지가 동일한 데이터를 사용하도록 통합
class SampleData {
  SampleData._(); // 인스턴스 생성 방지

  // ========== 통합된 냉장고 아이템 데이터 ==========

  /// 냉장고 전체 아이템 데이터 (타임라인과 냉장고 페이지 공통 사용)
  /// 이 하나의 리스트에서 모든 냉장고 관련 데이터를 가져옵니다
  static final List<FridgeItem> fridgeItems = [
    // 위험 구간 (1주 이하) - 빨간색
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

    // 주의 구간 (1-4주) - 주황색
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

    // 안전 구간 (4주 이상) - 초록색
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

  /// 타임라인용 아이템들 (fridgeItems에서 필터링하여 사용)
  /// 이제 별도의 데이터가 아닌 fridgeItems의 참조입니다
  static List<FridgeItem> get timelineItems => fridgeItems;

  // ========== 메뉴 추천 샘플 데이터 ==========

  /// 홈페이지 메뉴 추천용 데이터
  static final List<MenuRec> menuRecommendations = [
    const MenuRec(
      title: '된장찌개',
      needMessage: '애호박, 된장 재료가 꼭 필요해요!',
      goodMessage: '치킨스톡 재료가 있으면 더 좋아요!',
      minDaysLeft: 1,
      frequency: 2,
      favorite: false,
      hasAllRequired: false, // ⚠ 필수 재료 부족
    ),
    const MenuRec(
      title: '간장계란밥',
      needMessage: '',
      goodMessage: '참기름 재료가 있으면 더 좋아요!',
      minDaysLeft: 2,
      frequency: 5,
      favorite: true,
      hasAllRequired: true, // ✅ 모두 있음
    ),
    const MenuRec(
      title: '김치볶음밥',
      needMessage: '',
      goodMessage: '베이컨, 햄이 있으면 더 맛있어요!',
      minDaysLeft: 10,
      frequency: 4,
      favorite: true,
      hasAllRequired: true, // ✅ 김치 있음
    ),
    const MenuRec(
      title: '버터스크램블',
      needMessage: '',
      goodMessage: '체다치즈, 파슬리가 있으면 완벽해요!',
      minDaysLeft: 2,
      frequency: 3,
      favorite: false,
      hasAllRequired: true, // ✅ 계란, 버터 있음
    ),
    const MenuRec(
      title: '양파볶음',
      needMessage: '',
      goodMessage: '간장, 설탕이 있으면 더 달콤해요!',
      minDaysLeft: 15,
      frequency: 2,
      favorite: false,
      hasAllRequired: true, // ✅ 양파 있음
    ),
    const MenuRec(
      title: '마늘볶음밥',
      needMessage: '',
      goodMessage: '햄, 당근이 있으면 더 푸짐해요!',
      minDaysLeft: 20,
      frequency: 3,
      favorite: false,
      hasAllRequired: true, // ✅ 마늘 있음
    ),
    const MenuRec(
      title: '알리오 파스타',
      needMessage: '파스타면, 올리브오일이 꼭 필요해요!',
      goodMessage: '파슬리, 치즈가 있으면 더 좋아요!',
      minDaysLeft: 120,
      frequency: 3,
      favorite: true,
      hasAllRequired: true, // ✅ 파스타, 올리브오일 있음
    ),
    const MenuRec(
      title: '치즈토스트',
      needMessage: '식빵이 꼭 필요해요!',
      goodMessage: '토마토, 햄이 있으면 더 풍성해요!',
      minDaysLeft: 25,
      frequency: 4,
      favorite: false,
      hasAllRequired: false, // ⚠ 식빵 부족
    ),
    const MenuRec(
      title: '감자볶음',
      needMessage: '',
      goodMessage: '양파, 당근이 있으면 더 맛있어요!',
      minDaysLeft: 28,
      frequency: 2,
      favorite: false,
      hasAllRequired: true, // ✅ 감자 있음
    ),
    const MenuRec(
      title: '스크램블 에그',
      needMessage: '',
      goodMessage: '치즈, 허브가 있으면 고급스러워요!',
      minDaysLeft: 2,
      frequency: 6,
      favorite: true,
      hasAllRequired: true, // ✅ 계란 있음
    ),
    const MenuRec(
      title: '우유 시리얼',
      needMessage: '시리얼이 꼭 필요해요!',
      goodMessage: '과일, 견과류가 있으면 영양만점!',
      minDaysLeft: 3,
      frequency: 7,
      favorite: false,
      hasAllRequired: false, // ⚠ 시리얼 부족
    ),
    const MenuRec(
      title: '계란후라이',
      needMessage: '',
      goodMessage: '토스트, 샐러드가 있으면 완벽한 한 끼!',
      minDaysLeft: 2,
      frequency: 8,
      favorite: true,
      hasAllRequired: true, // ✅ 계란 있음
    ),
  ];

  // ========== 레시피 샘플 데이터 ==========

  /// 레시피 페이지용 데이터
  static final List<Recipe> recipes = [
    Recipe.sample(
      title: 'Fresh Garden Salad',
      timeMin: 10,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 4,
      tags: ['quick', 'vegetarian', 'healthy'],
    ),
    Recipe.sample(
      title: 'Vegetable Soup',
      timeMin: 45,
      servings: 4,
      difficulty: 'easy',
      ingredientsHave: 5,
      ingredientsTotal: 7,
      tags: ['vegetarian', 'healthy'],
    ),
    Recipe.sample(
      title: 'Creamy Chicken Pasta',
      timeMin: 25,
      servings: 2,
      difficulty: 'medium',
      ingredientsHave: 6,
      ingredientsTotal: 8,
      tags: ['quick'],
    ),
    Recipe.sample(
      title: 'Mushroom Risotto',
      timeMin: 35,
      servings: 3,
      difficulty: 'medium',
      ingredientsHave: 4,
      ingredientsTotal: 9,
      tags: ['vegetarian'],
    ),
    Recipe.sample(
      title: 'Quick Omelet',
      timeMin: 5,
      servings: 1,
      difficulty: 'easy',
      ingredientsHave: 3,
      ingredientsTotal: 3,
      tags: ['quick', 'vegetarian'],
    ),
    Recipe.sample(
      title: 'Beef Stir Fry',
      timeMin: 20,
      servings: 2,
      difficulty: 'easy',
      ingredientsHave: 5,
      ingredientsTotal: 6,
      tags: ['quick'],
    ),
    Recipe.sample(
      title: 'Chocolate Cake',
      timeMin: 90,
      servings: 8,
      difficulty: 'hard',
      ingredientsHave: 2,
      ingredientsTotal: 12,
      tags: ['dessert'],
    ),
    Recipe.sample(
      title: 'Vegan Buddha Bowl',
      timeMin: 30,
      servings: 2,
      difficulty: 'medium',
      ingredientsHave: 7,
      ingredientsTotal: 10,
      tags: ['vegetarian', 'vegan', 'healthy'],
    ),
  ];

  // ========== 유틸리티 메서드 (업데이트됨) ==========

  /// 위험도별 냉장고 아이템 개수 반환 (통합 데이터 사용)
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

  /// 레시피 필터별 개수 반환
  static Map<String, int> get recipeCounts {
    return {
      'Can make now': recipes.where((r) => r.canMakeNow).length,
      'Almost ready': recipes.where((r) => r.isAlmostReady).length,
      'Quick meals': recipes.where((r) => r.isQuickMeal).length,
      'Vegetarian': recipes.where((r) => r.isVegetarian).length,
    };
  }

  /// 메뉴 추천 통계 반환
  static Map<String, int> get menuStats {
    final available = menuRecommendations.where((m) => m.hasAllRequired).length;
    final total = menuRecommendations.length;
    final urgent = menuRecommendations.where((m) => m.minDaysLeft <= 7).length;

    return {
      'available': available,
      'total': total,
      'urgent': urgent,
      'missing': total - available,
    };
  }

  /// 사용자명 반환 (설정 가능)
  static String get userName => '공육공육공';

  /// 특정 위치의 냉장고 아이템만 필터링 (통합 데이터 사용)
  static List<FridgeItem> getFridgeItemsByLocation(String location) {
    if (location == 'All') return fridgeItems;
    return fridgeItems.where((item) => item.location == location).toList();
  }

  /// 특정 시간 범위의 냉장고 아이템만 필터링 (타임라인용)
  static List<FridgeItem> getFridgeItemsByTimeFilter(int maxDays) {
    return fridgeItems.where((item) => item.daysLeft <= maxDays).toList();
  }

  /// 특정 태그를 가진 레시피만 필터링
  static List<Recipe> getRecipesByTag(String tag) {
    return recipes.where((recipe) => recipe.tags.contains(tag)).toList();
  }

  /// 특정 조건의 레시피만 필터링
  static List<Recipe> getRecipesByCondition(String condition) {
    switch (condition) {
      case 'Can make now':
        return recipes.where((r) => r.canMakeNow).toList();
      case 'Almost ready':
        return recipes.where((r) => r.isAlmostReady).toList();
      case 'Quick meals':
        return recipes.where((r) => r.isQuickMeal).toList();
      case 'Vegetarian':
        return recipes.where((r) => r.isVegetarian).toList();
      default:
        return recipes;
    }
  }
}
