/// 레시피 모델
/// 레시피 페이지에서 사용하는 레시피 정보를 담는 클래스
class Recipe {
  final String title; // 레시피명 (예: "Fresh Garden Salad")
  final int timeMin; // 조리시간 (분)
  final int servings; // 몇 인분
  final String difficulty; // 난이도 ("easy", "medium", "hard")
  final int ingredientsHave; // 보유한 재료 개수
  final int ingredientsTotal; // 필요한 총 재료 개수
  final List<String> tags; // 태그 (예: ["quick", "vegetarian"])
  final String? imageUrl; // 이미지 URL (선택사항)
  final String? description; // 간단한 설명 (선택사항)

  const Recipe({
    required this.title,
    required this.timeMin,
    required this.servings,
    required this.difficulty,
    required this.ingredientsHave,
    required this.ingredientsTotal,
    required this.tags,
    this.imageUrl,
    this.description,
  });

  /// 재료 완성도 비율 (0.0 ~ 1.0)
  double get ingredientProgress {
    if (ingredientsTotal == 0) return 0.0;
    return (ingredientsHave / ingredientsTotal).clamp(0.0, 1.0);
  }

  /// 바로 만들 수 있는지 여부
  bool get canMakeNow => ingredientsHave >= ingredientsTotal;

  /// 거의 완성된 레시피인지 (2개 이하 재료 부족)
  bool get isAlmostReady =>
      (ingredientsTotal - ingredientsHave) <= 2 && !canMakeNow;

  /// 빠른 요리인지 (30분 이하)
  bool get isQuickMeal => timeMin <= 30;

  /// 채식 요리인지
  bool get isVegetarian => tags.contains('vegetarian');

  /// 비건 요리인지
  bool get isVegan => tags.contains('vegan');

  /// 건강식인지
  bool get isHealthy => tags.contains('healthy');

  /// 난이도 레벨 (숫자)
  int get difficultyLevel {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 1;
    }
  }

  /// 난이도 한글 변환
  String get difficultyKorean {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '쉬움';
      case 'medium':
        return '보통';
      case 'hard':
        return '어려움';
      default:
        return '쉬움';
    }
  }

  /// 조리시간 포맷팅 (예: "25분", "1시간 30분")
  String get formattedTime {
    if (timeMin < 60) {
      return '${timeMin}분';
    } else {
      final hours = timeMin ~/ 60;
      final minutes = timeMin % 60;
      if (minutes == 0) {
        return '${hours}시간';
      } else {
        return '${hours}시간 ${minutes}분';
      }
    }
  }

  /// 인분 포맷팅
  String get formattedServings {
    return '${servings}인분';
  }

  /// 부족한 재료 개수
  int get missingIngredients =>
      (ingredientsTotal - ingredientsHave).clamp(0, ingredientsTotal);

  /// 레시피 점수 계산 (추천 알고리즘용)
  double get recipeScore {
    double score = 0;

    // 재료 완성도 점수 (0-100점)
    score += ingredientProgress * 100;

    // 빠른 요리 보너스
    if (isQuickMeal) score += 20;

    // 쉬운 난이도 보너스
    if (difficultyLevel == 1) score += 15;

    // 건강식 보너스
    if (isHealthy) score += 10;

    // 채식 보너스
    if (isVegetarian) score += 5;

    return score;
  }

  /// 샘플 데이터 생성 팩토리
  factory Recipe.sample({
    required String title,
    required int timeMin,
    required int servings,
    required String difficulty,
    required int ingredientsHave,
    required int ingredientsTotal,
    List<String> tags = const [],
  }) {
    return Recipe(
      title: title,
      timeMin: timeMin,
      servings: servings,
      difficulty: difficulty,
      ingredientsHave: ingredientsHave,
      ingredientsTotal: ingredientsTotal,
      tags: tags,
    );
  }

  /// 복사본 생성 (일부 속성 변경)
  Recipe copyWith({
    String? title,
    int? timeMin,
    int? servings,
    String? difficulty,
    int? ingredientsHave,
    int? ingredientsTotal,
    List<String>? tags,
    String? imageUrl,
    String? description,
  }) {
    return Recipe(
      title: title ?? this.title,
      timeMin: timeMin ?? this.timeMin,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      ingredientsHave: ingredientsHave ?? this.ingredientsHave,
      ingredientsTotal: ingredientsTotal ?? this.ingredientsTotal,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Recipe(title: $title, progress: ${ingredientProgress.toStringAsFixed(1)}, time: ${timeMin}m)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe &&
        other.title == title &&
        other.timeMin == timeMin &&
        other.servings == servings;
  }

  @override
  int get hashCode {
    return title.hashCode ^ timeMin.hashCode ^ servings.hashCode;
  }
}
