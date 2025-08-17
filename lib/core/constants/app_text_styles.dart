import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 전체에서 사용하는 텍스트 스타일 상수들
/// 일관된 텍스트 스타일링을 위해 모든 스타일을 한 곳에서 관리
class AppTextStyles {
  AppTextStyles._(); // 인스턴스 생성 방지

  // ========== 제목 스타일 ==========

  /// 페이지 메인 제목 (24px, Bold)
  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  /// 섹션 제목 (18px, Bold)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 카드 제목 (16px, Bold)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 서브 제목 (16px, Medium)
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // ========== 본문 스타일 ==========

  /// 기본 본문 텍스트 (14px, Regular)
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// 보조 본문 텍스트 (14px, Regular, 회색)
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  /// 작은 본문 텍스트 (12px, Regular)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// 작은 보조 텍스트 (12px, Regular, 회색)
  static const TextStyle bodySmallSecondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // ========== 캡션 스타일 ==========

  /// 캡션 텍스트 (10px, Medium)
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// 작은 캡션 (10px, Regular)
  static const TextStyle captionSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
  );

  // ========== 버튼 스타일 ==========

  /// 버튼 텍스트 (14px, SemiBold)
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  /// 작은 버튼 텍스트 (12px, SemiBold)
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // ========== 네비게이션 스타일 ==========

  /// 네비게이션 라벨 (13px, Normal)
  static const TextStyle navLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
  );

  /// 선택된 네비게이션 라벨 (13px, Bold)
  static const TextStyle navLabelSelected = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  // ========== 상태별 스타일 ==========

  /// 위험 상태 텍스트 (빨간색)
  static const TextStyle danger = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.danger,
  );

  /// 경고 상태 텍스트 (주황색)
  static const TextStyle warning = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );

  /// 성공 상태 텍스트 (초록색)
  static const TextStyle success = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );

  // ========== 특수 스타일 ==========

  /// 힌트 텍스트 (입력 필드용)
  static const TextStyle hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
  );

  /// 페이지 서브타이틀 (헤더 아래 설명)
  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFFFFFFFF), // 흰색의 70% 투명도
  );

  /// 숫자 표시용 (카운트, 진행률 등)
  static const TextStyle number = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 작은 숫자 표시용
  static const TextStyle numberSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // ========== 필터/칩 스타일 ==========

  /// 필터 칩 텍스트 (선택되지 않음)
  static const TextStyle filterChip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 선택된 필터 칩 텍스트
  static const TextStyle filterChipSelected = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ========== 메뉴 추천 스타일 ==========

  /// 메뉴 제목
  static const TextStyle menuTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 메뉴 설명 (재료 관련)
  static TextStyle menuDescription(Color color) =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: color);

  // ========== 레시피 스타일 ==========

  /// 레시피 난이도 배지
  static const TextStyle recipeDifficulty = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// 레시피 메타 정보 (시간, 인분 등)
  static const TextStyle recipeMeta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // ========== 유틸리티 메서드 ==========

  /// 색상을 변경한 텍스트 스타일 반환
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// 폰트 크기를 변경한 텍스트 스타일 반환
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// 폰트 굵기를 변경한 텍스트 스타일 반환
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// 여러 속성을 한 번에 변경한 텍스트 스타일 반환
  static TextStyle withProperties(
    TextStyle style, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return style.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}
