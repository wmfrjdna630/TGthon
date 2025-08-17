/// 메뉴 추천 모델
/// 홈페이지에서 사용자에게 추천할 메뉴 정보를 담는 클래스
class MenuRec {
  final String title; // 메뉴명 (예: "김치볶음밥", "된장찌개")
  final String needMessage; // 필수 재료 부족 시 메시지
  final String goodMessage; // 선택 재료가 있을 때 메시지
  final int minDaysLeft; // 관련 재료 중 가장 임박한 유통기한
  final int frequency; // 사용 빈도 (1-10, 높을수록 자주 만드는 메뉴) - 클릭할 때마다 증가
  final bool favorite; // 즐겨찾기 여부
  final bool hasAllRequired; // 필수 재료 보유 여부
  final int clickCount; // 클릭 횟수 (새로 추가) - 빈도 계산에 사용
  final DateTime? lastClicked; // 마지막 클릭 시간 (새로 추가) - 최근성 반영

  const MenuRec({
    required this.title,
    required this.needMessage,
    required this.goodMessage,
    required this.minDaysLeft,
    required this.frequency,
    required this.favorite,
    required this.hasAllRequired,
    this.clickCount = 0, // 기본값 0
    this.lastClicked, // 기본값 null
  });

  /// 실제 사용 빈도 계산 (기본 빈도 + 클릭 가중치)
  /// 클릭 횟수와 최근성을 반영한 동적 빈도 점수
  double get actualFrequency {
    double score = frequency.toDouble();

    // 클릭 횟수 가중치 (클릭 1회당 0.5점씩 추가)
    score += clickCount * 0.5;

    // 최근성 가중치 (최근 7일 내 클릭 시 추가 점수)
    if (lastClicked != null) {
      final daysSinceLastClick = DateTime.now().difference(lastClicked!).inDays;
      if (daysSinceLastClick <= 7) {
        // 최근 일주일 내 클릭: 2점 추가
        score += 2.0;
      } else if (daysSinceLastClick <= 30) {
        // 최근 한달 내 클릭: 1점 추가
        score += 1.0;
      }
    }

    return score;
  }

  /// 메뉴 우선순위 계산 (기존 + 실제 빈도 반영)
  /// 필수재료 보유 + 유통기한 + 실제 빈도를 종합한 점수
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

    // 실제 사용 빈도 점수 (최대 50점) - 기존 30점에서 증가
    score += actualFrequency * 5; // 빈도의 영향력 증가

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

  /// 인기도 레벨 반환 (클릭 기반)
  String get popularityLevel {
    if (clickCount >= 10) return '매우 인기';
    if (clickCount >= 5) return '인기';
    if (clickCount >= 2) return '보통';
    return '신규';
  }

  /// 메뉴 클릭 시 빈도 증가 (새로 추가)
  MenuRec incrementClick() {
    return copyWith(
      clickCount: clickCount + 1,
      lastClicked: DateTime.now(),
      frequency: frequency, // 기본 빈도는 유지, actualFrequency에서 계산
    );
  }

  /// 복사본 생성 (일부 속성 변경) - clickCount, lastClicked 추가
  MenuRec copyWith({
    String? title,
    String? needMessage,
    String? goodMessage,
    int? minDaysLeft,
    int? frequency,
    bool? favorite,
    bool? hasAllRequired,
    int? clickCount,
    DateTime? lastClicked,
  }) {
    return MenuRec(
      title: title ?? this.title,
      needMessage: needMessage ?? this.needMessage,
      goodMessage: goodMessage ?? this.goodMessage,
      minDaysLeft: minDaysLeft ?? this.minDaysLeft,
      frequency: frequency ?? this.frequency,
      favorite: favorite ?? this.favorite,
      hasAllRequired: hasAllRequired ?? this.hasAllRequired,
      clickCount: clickCount ?? this.clickCount,
      lastClicked: lastClicked ?? this.lastClicked,
    );
  }

  @override
  String toString() {
    return 'MenuRec(title: $title, hasAllRequired: $hasAllRequired, frequency: $frequency, clickCount: $clickCount)';
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
