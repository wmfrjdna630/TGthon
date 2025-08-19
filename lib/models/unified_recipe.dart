// lib/models/unified_recipe.dart
import 'menu_rec.dart';
import 'recipe.dart';

/// 홈(MenuRec)과 레시피(Recipe)를 하나의 데이터로 관리하기 위한 통합 모델.
/// - 하나의 더미에서 파생하여 두 화면이 각각 필요한 속성만 사용하게 함.
class UnifiedRecipe {
  // 공통
  final String title; // 메뉴명 (한글)
  final String cuisine; // '한식' | '중식' | '양식' | '일식' | '간식'

  // 레시피 페이지 전용(시간/난이도/재료 보유율/태그)
  final int timeMin;
  final int servings;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final int ingredientsHave;
  final int ingredientsTotal;
  final List<String> tags; // 검색/필터 태그. cuisine도 포함시킴.

  // 홈 메뉴 추천 전용(유통기한/메시지/즐겨찾기/빈도)
  final String needMessage;
  final String goodMessage;
  final int minDaysLeft;
  final int frequency;
  final bool favorite;
  final bool hasAllRequired;
  final int clickCount;
  final DateTime? lastClicked;

  const UnifiedRecipe({
    required this.title,
    required this.cuisine,
    required this.timeMin,
    required this.servings,
    required this.difficulty,
    required this.ingredientsHave,
    required this.ingredientsTotal,
    required this.tags,
    required this.needMessage,
    required this.goodMessage,
    required this.minDaysLeft,
    required this.frequency,
    required this.favorite,
    required this.hasAllRequired,
    this.clickCount = 0,
    this.lastClicked,
  });

  /// 홈 위젯에서 쓰는 MenuRec로 변환
  MenuRec asMenuRec() {
    return MenuRec(
      title: title,
      needMessage: needMessage,
      goodMessage: goodMessage,
      minDaysLeft: minDaysLeft,
      frequency: frequency,
      favorite: favorite,
      hasAllRequired: hasAllRequired,
      clickCount: clickCount,
      lastClicked: lastClicked,
    );
  }

  /// 레시피 페이지에서 쓰는 Recipe로 변환
  Recipe asRecipe() {
    // cuisine(예: '한식')을 태그에 반드시 포함시켜 필터링에 쓰게 함.
    final mergedTags = {
      ...tags.map((e) => e.trim()),
      cuisine, // 한식/중식/양식/일식/간식
    }.toList();

    return Recipe(
      title: title,
      timeMin: timeMin,
      servings: servings,
      difficulty: difficulty,
      ingredientsHave: ingredientsHave,
      ingredientsTotal: ingredientsTotal,
      tags: mergedTags,
    );
  }
}
