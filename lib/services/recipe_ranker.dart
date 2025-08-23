// lib/services/recipe_ranker.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../models/menu_rec.dart';
import '../models/fridge_item.dart';

/// 점수 = 필수재료 보유(100) + 유통기한 임박도(50) + 사용자 선호도(50) + 즐겨찾기(20)
class RecipeRanker {
  final Map<String, FridgeItem> _fridgeIndex;
  final UserPreferenceProvider _prefs;

  RecipeRanker({
    required List<FridgeItem> fridgeItems,
    UserPreferenceProvider? preferences,
  })  : _fridgeIndex = _indexFridge(fridgeItems),
        _prefs = preferences ?? const _ZeroPreferenceProvider();

  double score({required Recipe recipe, required MenuRec menu}) {
    double total = 0;

    // ① 필수재료 보유(모두 보유 시 100점)
    total += _essentialPossession100(recipe);

    // ② 임박도(최대 50점) — 제목/태그로 후보 추출 → 냉장고 매칭 → 가장 임박한 재료 반영
    total += _urgencyUpTo50(recipe: recipe, menu: menu);

    // ③ 사용자 선호도(0~50)
    total += _prefs.preferenceScore(menu: menu, recipe: recipe).clamp(0.0, 50.0);

    // ④ 즐겨찾기(0/20)
    total += menu.favorite ? 20.0 : 0.0;

    return total;
  }

  List<MenuRec> sortByPriority({
    required List<MenuRec> menus,
    required Map<String, Recipe> recipeByTitle,
  }) {
    final pairs = <(MenuRec, double)>[];
    for (final m in menus) {
      final r = recipeByTitle[m.title];
      if (r == null) continue;
      final s = score(recipe: r, menu: m);
      pairs.add((m, s));
    }
    pairs.sort((a, b) => b.$2.compareTo(a.$2));
    return pairs.map((e) => e.$1).toList();
  }

  // ───────── 내부 유틸 ─────────

  static Map<String, FridgeItem> _indexFridge(List<FridgeItem> items) {
    final map = <String, FridgeItem>{};
    for (final it in items) {
      final k = _norm(it.name);
      if (k.isNotEmpty) map[k] = it;
    }
    return map;
  }

  static String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_/]'), '')
        .replaceAll(RegExp(r'[(){}\[\]·.,]'), '')
        .trim();
  }

  double _essentialPossession100(Recipe r) {
    if (r.ingredientsTotal <= 0) return 0.0;
    return (r.ingredientsHave >= r.ingredientsTotal) ? 100.0 : 0.0;
  }

  double _urgencyUpTo50({required Recipe recipe, required MenuRec menu}) {
    final candidates = _ingredientCandidates(recipe, menu);
    if (candidates.isEmpty) return 0.0;

    double minRemainRatio = 1.0;
    for (final c in candidates) {
      final it = _fridgeIndex[c];
      if (it == null) continue;
      final total = (it.totalDays <= 0) ? 1 : it.totalDays;
      final remainRatio = (it.daysLeft.clamp(0, total)) / total;
      minRemainRatio = min(minRemainRatio, remainRatio);
    }
    if (minRemainRatio == 1.0) return 0.0;

    final urgency = (1.0 - minRemainRatio).clamp(0.0, 1.0);
    return 50.0 * urgency;
  }

  List<String> _ingredientCandidates(Recipe r, MenuRec m) {
    final set = <String>{};

    // 태그 기반 후보
    for (final t in r.tags) {
      final n = _norm(t);
      if (n.isNotEmpty) set.add(n);
    }

    // 제목 토큰 기반 후보
    final titleTokens = m.title
        .toLowerCase()
        .split(RegExp(r'[\s\-_/]'))
        .map(_norm)
        .where((e) => e.length >= 2);
    set.addAll(titleTokens);

    // 불용어 제거
    const stop = {
      '요리','레시피','맛있','메뉴','간단','초간단','초스피드','한그릇',
      '볶음','조림','찜','탕','국','면','밥','샐러드','스프','스튜',
      '추천','비법','꿀팁','만드는법','레시피공유'
    };
    set.removeWhere((e) => stop.contains(e));

    return set.toList();
  }
}

/// 사용자 선호 점수(0~50)
abstract class UserPreferenceProvider {
  double preferenceScore({required MenuRec menu, required Recipe recipe});
}

/// 기본: 선호도 정보 없으면 0점
class _ZeroPreferenceProvider implements UserPreferenceProvider {
  const _ZeroPreferenceProvider();
  @override
  double preferenceScore({required MenuRec menu, required Recipe recipe}) => 0.0;
}

/// 클릭 수 기반 선호도(예시)
class ClickBasedPreference implements UserPreferenceProvider {
  const ClickBasedPreference();
  @override
  double preferenceScore({required MenuRec menu, required Recipe recipe}) {
    final c = menu.clickCount;
    if (c <= 0) return 0.0;
    // 20회 근처부터 포화
    final v = (log(c + 1) / log(20)).clamp(0.0, 1.0);
    return 50.0 * v;
  }
}
