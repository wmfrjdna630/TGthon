// lib/screens/home/home_types.dart

/// 홈/타임라인 공용 정렬 모드
enum SortMode { expiry, frequency, favorite }

/// 홈/타임라인 공용 시간 필터
/// - week: 1주(7일)
/// - month: 1개월(28일, UI 기준 4주)
/// - third: 3개월(90일)
enum TimeFilter { week, month, third }
