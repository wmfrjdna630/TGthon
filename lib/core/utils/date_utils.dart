/// 날짜 관련 유틸리티 함수들
/// 유통기한, 날짜 포맷팅, 날짜 계산 등을 처리
class DateUtils {
  DateUtils._(); // 인스턴스 생성 방지

  // ========== 날짜 포맷팅 ==========

  /// 남은 일수를 텍스트로 변환
  /// 예: 0일 -> "오늘", 1일 -> "내일", 2일 -> "2일 후"
  static String formatDaysLeft(int daysLeft) {
    if (daysLeft == 0) return '오늘';
    if (daysLeft == 1) return '내일';
    if (daysLeft < 0) return '${(-daysLeft)}일 지남';
    return '${daysLeft}일 후';
  }

  /// 영어로 남은 일수 텍스트 변환
  /// 예: 0일 -> "Today", 1일 -> "Tomorrow", 2일 -> "2d left"
  static String formatDaysLeftEn(int daysLeft) {
    if (daysLeft == 0) return 'Today';
    if (daysLeft == 1) return 'Tomorrow';
    if (daysLeft < 0) return '${(-daysLeft)}d overdue';
    return '${daysLeft}d left';
  }

  /// 날짜를 yyyy-MM-dd 형식으로 포맷팅
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 날짜를 MM월 dd일 형식으로 포맷팅
  static String formatDateKorean(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  /// 날짜를 상대적 시간으로 표현
  /// 예: "3시간 전", "2일 전", "1주일 전"
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주일 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }

  // ========== 날짜 계산 ==========

  /// 현재 날짜에서 며칠 후의 날짜 계산
  static DateTime addDays(int days) {
    return DateTime.now().add(Duration(days: days));
  }

  /// 두 날짜 사이의 일수 차이 계산
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  /// 오늘부터 특정 날짜까지 남은 일수 계산
  static int daysUntil(DateTime targetDate) {
    final today = DateTime.now();
    return daysBetween(today, targetDate);
  }

  /// 유통기한 만료일로부터 남은 일수 계산
  static int daysLeftFromExpiry(DateTime expiryDate) {
    return daysUntil(expiryDate);
  }

  // ========== 유통기한 관련 ==========

  /// 유통기한 상태 판별
  /// 'expired': 만료됨, 'danger': 위험(3일 이하), 'warning': 주의(7일 이하), 'safe': 안전
  static String getExpiryStatus(int daysLeft) {
    if (daysLeft < 0) return 'expired';
    if (daysLeft <= 3) return 'danger';
    if (daysLeft <= 7) return 'warning';
    return 'safe';
  }

  /// 유통기한 상태에 따른 메시지 반환
  static String getExpiryMessage(int daysLeft) {
    switch (getExpiryStatus(daysLeft)) {
      case 'expired':
        return '유통기한이 지났습니다';
      case 'danger':
        return '빨리 사용하세요';
      case 'warning':
        return '곧 만료됩니다';
      case 'safe':
      default:
        return '신선합니다';
    }
  }

  /// 영어 유통기한 메시지
  static String getExpiryMessageEn(int daysLeft) {
    switch (getExpiryStatus(daysLeft)) {
      case 'expired':
        return 'Expired';
      case 'danger':
        return 'Use soon';
      case 'warning':
        return 'Expiring';
      case 'safe':
      default:
        return 'Fresh';
    }
  }

  // ========== 시간 포맷팅 ==========

  /// 분을 시간:분 형식으로 변환
  /// 예: 90분 -> "1시간 30분", 45분 -> "45분"
  static String formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}분';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}시간';
    }

    return '${hours}시간 ${remainingMinutes}분';
  }

  /// 영어로 분을 시간:분 형식으로 변환
  static String formatMinutesEn(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }

  // ========== 검증 함수들 ==========

  /// 날짜가 오늘인지 확인
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// 날짜가 내일인지 확인
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// 날짜가 과거인지 확인
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// 날짜가 미래인지 확인
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // ========== 특수 날짜 계산 ==========

  /// 이번 주의 시작일 (월요일) 반환
  static DateTime getStartOfWeek([DateTime? date]) {
    date ??= DateTime.now();
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 이번 주의 마지막일 (일요일) 반환
  static DateTime getEndOfWeek([DateTime? date]) {
    date ??= DateTime.now();
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  /// 이번 달의 시작일 반환
  static DateTime getStartOfMonth([DateTime? date]) {
    date ??= DateTime.now();
    return DateTime(date.year, date.month, 1);
  }

  /// 이번 달의 마지막일 반환
  static DateTime getEndOfMonth([DateTime? date]) {
    date ??= DateTime.now();
    return DateTime(date.year, date.month + 1, 0);
  }

  // ========== 유틸리티 ==========

  /// 문자열을 DateTime으로 파싱 (yyyy-MM-dd 형식)
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// DateTime을 유니언 타임스탬프로 변환
  static int toTimestamp(DateTime date) {
    return date.millisecondsSinceEpoch ~/ 1000;
  }

  /// 유니언 타임스탬프를 DateTime으로 변환
  static DateTime fromTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
}
