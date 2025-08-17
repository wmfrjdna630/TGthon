/// 메뉴 추천 모델
/// 홈페이지에서 사용자에게 추천할 메뉴 정보를 담는 클래스
class MenuRec {
  final String title; // 메뉴명 (예: "김치볶음밥", "된장찌개")
  final String needMessage; // 필수 재료 부족 시 메시지
  final String goodMessage; // 선택 재료가 있을 때 메시지
  final int minDaysLeft; // 관련 재료 중 가장 임박한 유통기한
  final int frequency; // 사용 빈도 (1-10, 높을수록 자주 만드는 메뉴)
  final bool favorite; // 즐겨찾기 여부
  final bool hasAllRequired; // 필수 재료 보유 여부

  const MenuRec({
    required this.title,
    required this.needMessage,
    required this.goodMessage,
    required this.minDaysLeft,
    required this.frequency,
    required this.favorite,
    required this.hasAllRequired,
  });

  /// 메뉴 우선순위 계산
  /// 필수재료 보유 + 유통기한 + 빈도를 종합한 점수
  double get priorityScore {
    double score = 0;

    // 필수 재료가 있으면 기본 점수
    if (hasAllRequired) score += 100;

    // 유통기한이 임박할수록 높은 점수 (최대 50점)
    if (minDaysLeft <= 3) {
      score += 50;
    } else if (minDaysLeft <= 7) {
      score += 30;
    } else {
      score += 10;
    }

    // 사용 빈도 점수 (최대 30점)
    score += frequency * 3;

    // 즐겨찾기 보너스 (20점)
    if (favorite) score += 20;

    return score;
  }

  /// 메뉴 상태 텍스트 반환
  String get statusText {
    if (!hasAllRequired) return '재료 부족';
    if (minDaysLeft <= 3) return '재료 소진 임박';
    if (minDaysLeft <= 7) return '추천 메뉴';
    return '언제든 가능';
  }

  /// 메뉴 카테고리 반환 (간단한 분류)
  String get category {
    final titleLower = title.toLowerCase();

    if (titleLower.contains('밥') || titleLower.contains('rice')) {
      return '밥요리';
    } else if (titleLower.contains('찌개') ||
        titleLower.contains('국') ||
        titleLower.contains('soup')) {
      return '국물요리';
    } else if (titleLower.contains('계란') || titleLower.contains('egg')) {
      return '계란요리';
    } else if (titleLower.contains('파스타') || titleLower.contains('pasta')) {
      return '양식';
    } else {
      return '기타';
    }
  }

  /// 예상 조리시간 반환 (대략적)
  int get estimatedCookingMinutes {
    switch (category) {
      case '계란요리':
        return 10;
      case '밥요리':
        return 20;
      case '국물요리':
        return 45;
      case '양식':
        return 30;
      default:
        return 25;
    }
  }

  /// 복사본 생성 (일부 속성 변경)
  MenuRec copyWith({
    String? title,
    String? needMessage,
    String? goodMessage,
    int? minDaysLeft,
    int? frequency,
    bool? favorite,
    bool? hasAllRequired,
  }) {
    return MenuRec(
      title: title ?? this.title,
      needMessage: needMessage ?? this.needMessage,
      goodMessage: goodMessage ?? this.goodMessage,
      minDaysLeft: minDaysLeft ?? this.minDaysLeft,
      frequency: frequency ?? this.frequency,
      favorite: favorite ?? this.favorite,
      hasAllRequired: hasAllRequired ?? this.hasAllRequired,
    );
  }

  @override
  String toString() {
    return 'MenuRec(title: $title, hasAllRequired: $hasAllRequired, minDaysLeft: $minDaysLeft)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuRec &&
        other.title == title &&
        other.hasAllRequired == hasAllRequired &&
        other.minDaysLeft == minDaysLeft;
  }

  @override
  int get hashCode {
    return title.hashCode ^ hasAllRequired.hashCode ^ minDaysLeft.hashCode;
  }
}
