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

  static final Set<String> _unitTokens = {
    // 영문 단위
    'g', 'kg', 'mg', 'lb', 'lbs', 'oz',
    'l', 'ml', 'cc',
    'tsp', 'tbsp', 'cup', 'cups',
    // 한글 단위
    '큰술', '작은술', '숟가락', '스푼', '스푼들', '컵', '종이컵',
    '개', '알', '줌', '꼬집', '쪽', '줄기', '톨', '마리', '번',
    // 빈도/횟수·범위 표현
    '분', '시간',
  };

  static final Set<String> _stopWords = {
    // 양/수량 표현
    '약간', '조금', '적당량', '넉넉히', '소량', '중간', '큰', '작은', '적당히',
    // 조리 상태/수식
    '다진', '간', '채', '채썬', '썬', '잘게', '굵게', '볶은', '삶은', '데친', '구운',
    '간한', '간을', '간하여', '간해', '간맞춰',
    // 접속/조사
    '및', '또는', '또', '그리고', '와', '과', '또한',
    '의', '을', '를', '이', '가', '은', '는', '에', '로', '에서', '과의',
    // 기타 자주 섞이는 불용어
    '국물', '물', '육수', // 필요시 물/육수는 남기고 싶다면 여기서 빼세요
  };

  /// 문자열 재료를 토큰화 (단위/숫자/불용어 필터링 + 한글/영문 식재료만 남김)
  static List<String> tokenizeParts(String? parts) {
    if (parts == null || parts.trim().isEmpty) return const [];

    String s = parts.toLowerCase();

    // 1) 괄호 내용 제거 (대안 단위/설명 등)
    s = s.replaceAll(RegExp(r'[\(\)\[\]\{\}]'), ' ');

    // 2) 분수/범위/숫자+단위 제거 (예: 2/3개, 1-2컵, 100g, 200ml)
    //    - 먼저 숫자+단위 패턴 제거
    s = s.replaceAll(
      RegExp(
        r'\b\d+[./-]?\d*\s*(g|kg|mg|lb|lbs|oz|l|ml|cc|tsp|tbsp|cup|cups|큰술|작은술|숟가락|스푼|스푼들|컵|종이컵|개|알|줌|꼬집|쪽|줄기|톨|마리|분|시간)\b',
      ),
      ' ',
    );
    //    - “1~2”, “1-2” 같은 범위 숫자 제거
    s = s.replaceAll(RegExp(r'\b\d+\s*[\-~]\s*\d+\b'), ' ');
    //    - 나머지 숫자 제거 (순서 중요: 위에서 숫자+단위를 먼저 처리)
    s = s.replaceAll(RegExp(r'\b\d+[./]?\d*\b'), ' ');

    // 3) 구분자 통일 (쉼표, 슬래시, 중점, bullet, 콜론 등)
    s = s.replaceAll(RegExp(r'[^0-9a-zA-Z가-힣,./·∙•:\s-]'), ' ');
    final rawTokens = s.split(RegExp(r'[,/·∙•:\s]+'));

    // 4) 토큰 정리: 단위/불용어/한 글자 알파벳 제거, 접미 단위 제거
    final List<String> cleaned = [];
    for (var t in rawTokens) {
      t = t.trim();
      if (t.isEmpty) continue;

      // 영문 한 글자 토큰 제거 (수량 파편)
      if (RegExp(r'^[a-zA-Z]$').hasMatch(t)) continue;

      // 순수 단위 토큰 걸러내기
      if (_unitTokens.contains(t)) continue;

      // 접미 단위가 붙은 경우(숫자를 지운 뒤 남은 ‘g’, ‘ml’ 등) 잘라내기
      // 예: '소금g' 같은 비정상 경우 대비
      final m = RegExp(
        r'^(.*?)(g|kg|mg|lb|lbs|oz|l|ml|cc|tsp|tbsp|cup|cups|큰술|작은술|숟가락|스푼|스푼들|컵|종이컵|개|알|줌|꼬집|쪽|줄기|톨|마리)$',
      ).firstMatch(t);
      if (m != null) {
        t = m.group(1)!.trim();
        if (t.isEmpty) continue;
      }

      // 불용어 제거
      if (_stopWords.contains(t)) continue;

      // 너무 짧은 파편 제거 (한글 한 글자/기호 방지) — '파' 같은 재료를 쓰신다면 이 규칙은 빼세요.
      // if (t.length <= 1 && RegExp(r'^[가-힣]$').hasMatch(t)) continue;

      cleaned.add(t);
    }

    // 5) 중복 제거(재료 수는 '고유 재료' 기준이 더 자연스러움)
    final unique = cleaned.toSet().toList();

    return unique;
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
