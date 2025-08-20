// lib/models/api/foodsafety_recipe.dart
import 'package:flutter/foundation.dart';
import '../../data/sample_data.dart';
import '../unified_recipe.dart';

/// COOKRCP01의 1개 row를 표현하는 DTO
@immutable
class FoodSafetyRecipeDto {
  final String seq; // RCP_SEQ
  final String name; // RCP_NM
  final String? dishType; // RCP_PAT2 (반찬/국/후식/밥 등)
  final String? hashTag; // HASH_TAG (예: #간단 #집밥)
  final String? parts; // RCP_PARTS_DTLS (재료문자열)
  final String? imgSmall; // ATT_FILE_NO_MAIN
  final String? imgLarge; // ATT_FILE_NO_MK
  final List<String> manuals; // MANUAL01..20

  const FoodSafetyRecipeDto({
    required this.seq,
    required this.name,
    this.dishType,
    this.hashTag,
    this.parts,
    this.imgSmall,
    this.imgLarge,
    required this.manuals,
  });

  factory FoodSafetyRecipeDto.fromJson(Map<String, dynamic> j) {
    List<String> mans = [];
    for (int i = 1; i <= 20; i++) {
      final key = i < 10 ? 'MANUAL0$i' : 'MANUAL$i';
      final v = (j[key] as String?)?.trim();
      if (v != null && v.isNotEmpty) mans.add(v);
    }
    return FoodSafetyRecipeDto(
      seq: (j['RCP_SEQ'] ?? '').toString(),
      name: (j['RCP_NM'] ?? '').toString(),
      dishType: (j['RCP_PAT2'] as String?)?.trim(),
      hashTag: (j['HASH_TAG'] as String?)?.trim(),
      parts: (j['RCP_PARTS_DTLS'] as String?)?.trim(),
      imgSmall: (j['ATT_FILE_NO_MAIN'] as String?)?.trim(),
      imgLarge: (j['ATT_FILE_NO_MK'] as String?)?.trim(),
      manuals: mans,
    );
  }

  /// 문자열 재료를 토큰화
  static List<String> tokenizeParts(String? parts) {
    if (parts == null || parts.trim().isEmpty) return const [];
    final raw = parts
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)\[\]\{\}]'), ' ')
        .replaceAll(RegExp(r'[\d\.]+'), ' ')
        .replaceAll(RegExp(r'[^0-9a-zA-Z가-힣,./·∙•\s]'), ' ');
    final split = raw.split(RegExp(r'[,/·∙•\s]+'));
    return split.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  /// 우리 앱의 UnifiedRecipe로 변환
  UnifiedRecipe toUnified({
    required Set<String> owned, // 보유 재료 소문자 set
  }) {
    // 재료 파싱
    final tokens = tokenizeParts(parts);
    final total = tokens.length;
    final have = tokens.where((t) => owned.contains(t)).length;

    // 유통기한(최소 daysLeft) 추정: 보유 재료 중 매칭된 항목의 최소값
    int minDaysLeft = 365;
    for (final t in owned) {
      final find = SampleData.fridgeItems.firstWhere(
        (f) => f.name.trim().toLowerCase() == t,
        orElse: () => SampleData.fridgeItems.first,
      );
      if (tokens.contains(t)) {
        minDaysLeft = find.daysLeft < minDaysLeft ? find.daysLeft : minDaysLeft;
      }
    }
    if (minDaysLeft == 365) minDaysLeft = 30; // 매칭 없으면 넉넉하게

    // 태그 구성: 해시태그 분해 + dishType
    final tags = <String>[];
    if (dishType != null && dishType!.isNotEmpty) tags.add(dishType!);
    if (hashTag != null && hashTag!.isNotEmpty) {
      tags.addAll(
        hashTag!
            .replaceAll('#', ' ')
            .split(RegExp(r'\s+'))
            .where((e) => e.trim().isNotEmpty),
      );
    }

    // 난이도/시간은 API에 직접 없음 → 휴리스틱 기본값
    final bool quick = tags.any((t) => t.contains('간단') || t.contains('초간단'));
    final int timeMin = quick ? 20 : 35;
    final String difficulty = quick ? 'easy' : 'medium';

    return UnifiedRecipe(
      title: name,
      cuisine: _mapDishToCuisine(dishType),
      timeMin: timeMin,
      servings: 2,
      difficulty: difficulty,
      ingredientsHave: have,
      ingredientsTotal: total == 0 ? 6 : total, // 0 방지
      tags: tags,
      needMessage: _buildNeedMessage(tokens, owned, have, total),
      goodMessage: _buildGoodMessage(tokens, owned),
      minDaysLeft: minDaysLeft,
      frequency: 1,
      favorite: false,
      hasAllRequired: have >= (total == 0 ? 1 : total),
      clickCount: 0,
      lastClicked: null,
    );
  }

  static String _mapDishToCuisine(String? rcpPat2) {
    final v = (rcpPat2 ?? '').trim();
    if (v.isEmpty) return '기타';
    // API는 '반찬/국/후식/밥/면' 등 → 우리 카테고리로 그대로 둬도 됨
    return v;
  }

  static String _buildNeedMessage(
    List<String> tokens,
    Set<String> owned,
    int have,
    int total,
  ) {
    if (total == 0) return '';
    if (have >= total) return '';
    final miss = tokens.where((t) => !owned.contains(t)).take(3).toList();
    if (miss.isEmpty) return '';
    return '${miss.join(', ')} 재료가 꼭 필요해요!';
    // (최대 3개 노출)
  }

  static String _buildGoodMessage(List<String> tokens, Set<String> owned) {
    // 보유하면 더 좋은 보완재는 구분 불가 → 임시로 보유하지 않은 토큰 중 하나 노출
    final miss = tokens.where((t) => !owned.contains(t)).take(2).toList();
    if (miss.isEmpty) return '';
    return '${miss.join(', ')} 재료가 있으면 더 좋아요!';
  }
}
