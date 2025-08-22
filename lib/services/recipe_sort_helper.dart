// lib/services/recipe_sort_helper.dart
import '../models/menu_rec.dart';
import '../models/recipe.dart';
import '../screens/home/home_types.dart';

/// 홈/레시피 정렬 규칙 단일 소스
class RecipeSortHelper {
  /// 레시피 리스트를 title 기준으로 빠르게 찾기 위한 인덱스
  static Map<String, Recipe> buildRecipeIndex(List<Recipe> recipes) {
    final map = <String, Recipe>{};
    for (final r in recipes) {
      map[_key(r.title)] = r;
    }
    return map;
  }

  /// 레시피 페이지와 동일 규칙으로 메뉴를 정렬/필터
  static List<MenuRec> sortAndFilterMenus({
    required List<MenuRec> menus,
    required Map<String, Recipe> recipeByTitle,
    required SortMode mode,
    int expiryThresholdDays = 7, // 임박 기준(7일 미만)
  }) {
    // 복사본 작업 (원본 변형 방지)
    var list = List<MenuRec>.from(menus);

    int minDaysLeft(MenuRec m) => m.minDaysLeft;
    bool isExpiring(MenuRec m) {
      final d = minDaysLeft(m);
      return d >= 0 && d < expiryThresholdDays;
    }

    int missingFor(MenuRec m) {
      final r = recipeByTitle[_key(m.title)];
      if (r == null) return 9999; // 레시피 정보 없으면 맨 뒤로
      final need = r.ingredientsTotal;
      final have = r.ingredientsHave;
      final missing = need - have;
      return missing < 0 ? 0 : missing;
    }

    switch (mode) {
      case SortMode.expiry:
        // 임박(7일 미만)만 노출 후, 남은 일수/즐겨찾기/제목
        list = list.where(isExpiring).toList();
        list.sort((a, b) {
          final d = minDaysLeft(a).compareTo(minDaysLeft(b));
          if (d != 0) return d;
          if (a.favorite != b.favorite)
            return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
          return a.title.compareTo(b.title);
        });
        break;

      case SortMode.frequency:
        // ✅ 레시피 페이지와 동일: 보유재료 0개 제외 + 필요 재료 15개 "미만" 유지
        list = list.where((m) {
          final r = recipeByTitle[_key(m.title)];
          if (r == null) return false;
          if (r.ingredientsHave <= 0) return false;
          if (r.ingredientsTotal >= 15) return false; // "미만" 조건
          return true;
        }).toList();

        // (필요−보유) 오름차순 → 임박 여부(true 먼저) → 남은 일수 → 즐겨찾기 → 제목
        int boolDesc(bool v) => v ? 0 : 1; // true 먼저
        list.sort((a, b) {
          final ma = missingFor(a), mb = missingFor(b);
          final d0 = ma.compareTo(mb);
          if (d0 != 0) return d0;

          final d1 = boolDesc(isExpiring(b)).compareTo(boolDesc(isExpiring(a)));
          if (d1 != 0) return d1;

          final d2 = minDaysLeft(a).compareTo(minDaysLeft(b));
          if (d2 != 0) return d2;

          if (a.favorite != b.favorite)
            return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
          return a.title.compareTo(b.title);
        });
        break;

      case SortMode.favorite:
        // 즐겨찾기만 노출 후 제목순
        list = list.where((m) => m.favorite).toList();
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return list;
  }

  static String _key(String s) => s.trim().toLowerCase();
}
