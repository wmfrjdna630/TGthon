// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수들
/// 모든 색상을 한 곳에서 관리하여 일관성 유지 및 쉬운 수정 가능
class AppColors {
  AppColors._(); // 인스턴스 생성 방지

  // ========== 기본 브랜드 색상 (하늘색/파랑색 테마) ==========

  /// 메인 브랜드 색상 (파랑색) - 상단/하단 바용
  static const Color primary = Color.fromARGB(255, 30, 0, 255);

  /// 메인 색상의 밝은 버전 (밝은 파랑)
  static const Color primaryLight = Color(0xFF64B5F6);

  /// 메인 색상의 어두운 버전 (진한 파랑)
  static const Color primaryDark = Color.fromARGB(255, 30, 0, 255);

  // ========== 상태별 색상 ==========

  /// 위험 상태 (유통기한 7일 이하) - 빨간색
  static const Color danger = Color(0xFFE74C3C);

  /// 경고 상태 (유통기한 8-29일) - 주황색
  static const Color warning = Color(0xFFF39C12);

  /// 안전/성공 상태 (유통기한 30일 이상) - 초록색
  static const Color success = Color(0xFF2ECC71);

  /// 정보 상태
  static const Color info = Color.fromARGB(255, 30, 0, 255);

  // ========== 배경 색상 (하늘색 테마) ==========

  /// 앱 기본 배경색 (연한 하늘색)
  static const Color background = Color(0xFFF0F8FF);

  /// 카드 배경색 (순백색으로 대비)
  static const Color cardBackground = Colors.white;

  /// 냉동실 아이템 배경색 (차가운 파랑 계열)
  static const Color freezerBackground = Color(0xFFE3F2FD);

  /// 팬트리 아이템 배경색 (따뜻한 크림색)
  static const Color pantryBackground = Color(0xFFFFF8E1);

  /// 입력 필드 배경색 (밝은 회색)
  static const Color inputBackground = Color(0xFFF5F5F5);

  // ========== 텍스트 색상 ==========

  /// 기본 텍스트 색상
  static const Color textPrimary = Color(0xFF2C2C2C);

  /// 보조 텍스트 색상
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// 비활성 텍스트 색상
  static const Color textDisabled = Color(0xFF9E9E9E);

  /// 흰색 텍스트
  static const Color textWhite = Colors.white;

  // ========== 테두리 색상 ==========

  /// 기본 테두리 색상
  static const Color border = Color(0xFFE0E0E0);

  /// 활성 테두리 색상
  static const Color borderActive = primary;

  /// 오류 테두리 색상
  static const Color borderError = danger;

  // ========== 그림자 색상 ==========

  /// 기본 그림자 색상
  static const Color shadow = Colors.black12;

  /// 진한 그림자 색상
  static const Color shadowDark = Colors.black26;

  // ========== 네비게이션 색상 ==========

  /// 선택된 네비게이션 아이템 색상
  static const Color navSelected = primary;

  /// 선택되지 않은 네비게이션 아이템 색상
  static const Color navUnselected = Color(0xFF9E9E9E);

  // ========== 필터/칩 색상 (파랑 테마) ==========

  /// 선택된 필터 배경색 (연한 파랑)
  static const Color filterSelected = Color(0xFFE3F2FD);

  /// 선택되지 않은 필터 배경색
  static const Color filterUnselected = Colors.white;

  /// 필터 테두리 색상 (연한 파랑)
  static const Color filterBorder = Color(0xFFBBDEFB);

  // ========== 메뉴 추천 색상 (파랑 테마) ==========

  /// 모든 재료 보유 시 배경색 (연한 파랑)
  static const Color menuAvailable = Color(0xFFE8F4FD);

  /// 재료 부족 시 배경색 (연한 주황)
  static const Color menuMissing = Color(0xFFFFF3E0);

  /// 모든 재료 보유 시 테두리색 (파랑)
  static const Color menuAvailableBorder = Color(0xFFE8F4FD);

  /// 재료 부족 시 테두리색 (주황)
  static const Color menuMissingBorder = Color(0xFFFFF3E0);

  // ========== 진행률 바 색상 (파랑 테마) ==========

  /// 진행률 바 배경색 (연한 회색)
  static const Color progressBackground = Color(0xFFF0F0F0);

  /// 진행률 바 비활성 배경색
  static const Color progressInactive = Color(0xFFF8F8F8);

  // ========== 수정된 유통기한 그라데이션 색상 ==========

  /// 1주 필터용 그라데이션 (빨간색만)
  static const List<Color> timelineGradientWeek = [
    danger, // 빨간색
    danger, // 빨간색 (동일한 색상으로 단색 효과)
  ];

  /// 1개월 필터용 그라데이션 (빨간색 -> 주황색)
  static const List<Color> timelineGradientMonth = [
    danger, // 빨간색 (7일 이하)
    warning, // 주황색 (8-28일)
  ];

  /// 3개월 필터용 그라데이션 (빨간색 -> 주황색 -> 초록색)
  static const List<Color> timelineGradientThird = [
    danger, // 빨간색 (7일 이하)
    warning, // 주황색 (8-29일)
    success, // 초록색 (30일 이상)
  ];

  // ========== 투명도 변형 ==========

  /// 메인 색상 10% 투명도
  static Color get primaryWithOpacity10 => primary.withValues(alpha: 0.1);

  /// 메인 색상 20% 투명도
  static Color get primaryWithOpacity20 => primary.withValues(alpha: 0.2);

  /// 위험 색상 10% 투명도
  static Color get dangerWithOpacity10 => danger.withValues(alpha: 0.1);

  /// 경고 색상 10% 투명도
  static Color get warningWithOpacity10 => warning.withValues(alpha: 0.1);

  /// 성공 색상 10% 투명도
  static Color get successWithOpacity10 =>
      const Color.fromARGB(255, 0, 0, 255).withValues(alpha: 0.1);

  // ========== 유틸리티 메서드들 ==========

  /// 유통기한 일수에 따른 색상 반환
  /// 7일 이하: 빨간색, 8-29일: 주황색, 30일 이상: 초록색
  static Color getColorByDaysLeft(int daysLeft) {
    if (daysLeft <= 7) return danger; // 7일 이하: 빨간색
    if (daysLeft < 30) return warning; // 8-29일: 주황색
    return success; // 30일 이상: 초록색
  }

  /// 필터 타입에 따른 그라데이션 색상 반환
  static List<Color> getTimelineGradient(String filterType) {
    switch (filterType) {
      case '1주':
        return timelineGradientWeek;
      case '1개월':
        return timelineGradientMonth;
      case '3개월':
        return timelineGradientThird;
      default:
        return timelineGradientThird;
    }
  }

  /// 필터 타입에 따른 그라데이션 stop 포인트 반환
  /// 🔴 중요: stops 배열의 길이는 colors 배열의 길이와 반드시 일치해야 함
  static List<double> getTimelineGradientStops(String filterType) {
    switch (filterType) {
      case '1주':
        // 2개 색상에 2개 stops (빨간색만 표시)
        return [0.0, 1.0];
      case '1개월':
        // 2개 색상에 2개 stops
        // 7일/28일 = 0.25 (빨간색이 전체의 25%)
        return [0.0, 0.25];
      case '3개월':
        // 3개 색상에 3개 stops
        // 7일/90일 = 0.08 (빨간색이 전체의 8%)
        // 30일/90일 = 0.33 (주황색이 전체의 33%까지)
        return [0.0, 0.08, 0.33];
      default:
        return [0.0, 0.08, 0.33];
    }
  }

  /// 진행률에 따른 색상 반환 (0.0 ~ 1.0)
  static Color getColorByProgress(double progress) {
    if (progress >= 0.8) return success; // 80% 이상: 초록색
    if (progress >= 0.5) return warning; // 50-80%: 주황색
    return danger; // 50% 미만: 빨간색
  }

  /// 난이도에 따른 색상 반환
  static Color getColorByDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return success;
      case 'medium':
        return warning;
      case 'hard':
        return danger;
      default:
        return success;
    }
  }
}
