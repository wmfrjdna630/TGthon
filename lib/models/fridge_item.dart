import 'package:flutter/material.dart';

/// 냉장고 아이템 모델
/// 냉장고에 보관된 식품의 정보를 담는 클래스
class FridgeItem {
  final String name; // 식품명 (예: "우유", "계란")
  final String amount; // 수량 (예: "1L", "500g", "6개")
  final String category; // 카테고리 (예: "유제품", "육류", "채소")
  final String location; // 보관위치 (예: "Fridge", "Freezer", "Pantry")
  final int daysLeft; // 남은 유통기한 (일 단위)
  final String status; // 상태 텍스트 (예: "신선함", "주의", "사용필요")
  final Color statusColor; // 상태 색상
  final Color background; // 카드 배경색
  final IconData icon; // 아이콘
  final int totalDays; // 전체 유통기한 (진행률 계산용)

  const FridgeItem({
    required this.name,
    required this.amount,
    required this.category,
    required this.location,
    required this.daysLeft,
    required this.status,
    required this.statusColor,
    required this.background,
    required this.icon,
    required this.totalDays,
  });

  /// 유통기한 진행률 계산 (0.0 ~ 1.0)
  double get progressRatio {
    if (totalDays <= 0) return 1.0;
    return ((totalDays - daysLeft).clamp(0, totalDays) / totalDays).clamp(
      0.0,
      1.0,
    );
  }

  /// 위험도 레벨 반환
  /// - danger: 7일 이하 (빨간색)
  /// - warning: 8-29일 (주황색)
  /// - safe: 30일 이상 (초록색)
  String get riskLevel {
    if (daysLeft <= 7) return 'danger'; // 7일 이하: 빨간색
    if (daysLeft < 30) return 'warning'; // 8-29일: 주황색
    return 'safe'; // 30일 이상: 초록색
  }

  /// 샘플 데이터 생성 팩토리
  factory FridgeItem.fromSampleData({
    required String name,
    required String amount,
    required String category,
    required String location,
    required int daysLeft,
    required int totalDays,
  }) {
    // ✅ 수정된 유통기한에 따른 상태 및 색상 결정 로직
    String status;
    Color statusColor;

    if (daysLeft <= 1) {
      // 1일 이하: 오늘까지/이미 지남
      status = 'Use today';
      statusColor = const Color(0xFFE74C3C); // 빨간색
    } else if (daysLeft <= 7) {
      // 2-7일: 일주일 이내
      status = 'Use soon';
      statusColor = const Color(0xFFE74C3C); // 빨간색
    } else if (daysLeft < 30) {
      // 8-29일: 한 달 이내
      status = 'Expiring';
      statusColor = const Color(0xFFF39C12); // 주황색
    } else {
      // 30일 이상: 신선함
      status = 'Fresh';
      statusColor = const Color(0xFF2ECC71); // 초록색
    }

    // 보관위치에 따른 배경색과 아이콘 결정 (기존 로직 유지)
    Color background;
    IconData icon;

    switch (location) {
      case 'Freezer':
        background = const Color(0xFFEFF5FF); // 파란계열
        icon = Icons.ac_unit;
        break;
      case 'Pantry':
        background = const Color(0xFFFFFBE5); // 노란계열
        icon = Icons.home;
        break;
      default: // Fridge
        background = Colors.white;
        icon = Icons.ac_unit;
    }

    return FridgeItem(
      name: name,
      amount: amount,
      category: category,
      location: location,
      daysLeft: daysLeft,
      status: status,
      statusColor: statusColor,
      background: background,
      icon: icon,
      totalDays: totalDays,
    );
  }

  /// 간단한 생성자 (타임라인용)
  factory FridgeItem.simple(String name, int daysLeft) {
    return FridgeItem(
      name: name,
      amount: '',
      category: '',
      location: 'Fridge',
      daysLeft: daysLeft,
      status: '',
      statusColor: Colors.grey,
      background: Colors.white,
      icon: Icons.food_bank,
      totalDays: 30,
    );
  }

  /// 복사본 생성 (일부 속성 변경)
  FridgeItem copyWith({
    String? name,
    String? amount,
    String? category,
    String? location,
    int? daysLeft,
    String? status,
    Color? statusColor,
    Color? background,
    IconData? icon,
    int? totalDays,
  }) {
    return FridgeItem(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      location: location ?? this.location,
      daysLeft: daysLeft ?? this.daysLeft,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      background: background ?? this.background,
      icon: icon ?? this.icon,
      totalDays: totalDays ?? this.totalDays,
    );
  }

  @override
  String toString() {
    return 'FridgeItem(name: $name, daysLeft: $daysLeft, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FridgeItem &&
        other.name == name &&
        other.amount == amount &&
        other.location == location;
  }

  @override
  int get hashCode {
    return name.hashCode ^ amount.hashCode ^ location.hashCode;
  }
}
