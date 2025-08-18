import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/fridge_item.dart';
import '../../models/menu_rec.dart';

/// 홈페이지 상단의 동적 헤더 위젯
/// 3초마다 다른 메시지로 변경되는 스마트 알림 제공
class DynamicHeader extends StatefulWidget {
  final List<FridgeItem> fridgeItems; // 냉장고 아이템들
  final List<MenuRec> menuRecommendations; // 메뉴 추천들
  final int todoCount; // 할일 개수

  const DynamicHeader({
    super.key,
    required this.fridgeItems,
    required this.menuRecommendations,
    required this.todoCount,
  });

  @override
  State<DynamicHeader> createState() => _DynamicHeaderState();
}

class _DynamicHeaderState extends State<DynamicHeader>
    with SingleTickerProviderStateMixin {
  // ========== 상태 변수들 ==========

  /// 현재 표시할 메시지 인덱스
  int _currentMessageIndex = 0;

  /// 메시지 자동 변경 타이머
  Timer? _messageTimer;

  /// 페이드 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ========== 라이프사이클 메서드들 ==========

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startMessageTimer();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ========== 애니메이션 설정 ==========

  /// 페이드 애니메이션 설정
  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  /// 메시지 자동 변경 타이머 시작
  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _changeMessage();
    });
  }

  /// 메시지 변경 애니메이션
  Future<void> _changeMessage() async {
    if (!mounted) return;

    // 페이드 아웃
    await _animationController.reverse();

    if (mounted) {
      // 다음 메시지로 변경
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _generateMessages().length;
      });

      // 페이드 인
      await _animationController.forward();
    }
  }

  // ========== 메시지 생성 로직 ==========

  /// 동적 메시지들 생성
  List<_HeaderMessage> _generateMessages() {
    final messages = <_HeaderMessage>[];

    // 1. 유통기한 임박 재료 메시지
    final urgentItems =
        widget.fridgeItems.where((item) => item.daysLeft <= 3).toList()
          ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    if (urgentItems.isNotEmpty) {
      final item = urgentItems.first;
      messages.add(
        _HeaderMessage(
          icon: Icons.warning_amber,
          title: '${item.name}의 유통기한이 임박했어요',
          subtitle: '${item.daysLeft}일 남음 • 빨리 사용해주세요',
          color: Colors.red,
          backgroundColor: Colors.red.shade50,
        ),
      );
    }

    // 2. 추천 메뉴 메시지
    final availableMenus =
        widget.menuRecommendations.where((menu) => menu.hasAllRequired).toList()
          ..sort((a, b) => a.minDaysLeft.compareTo(b.minDaysLeft));

    if (availableMenus.isNotEmpty) {
      final menu = availableMenus.first;
      messages.add(
        _HeaderMessage(
          icon: Icons.restaurant,
          title: '오늘 저녁은 "${menu.title}" 어떠세요?',
          subtitle: '모든 재료가 준비되어 있어요',
          color: Colors.green,
          backgroundColor: Colors.green.shade50,
        ),
      );
    }

    // 3. 할일 알림 메시지
    if (widget.todoCount > 0) {
      messages.add(
        _HeaderMessage(
          icon: Icons.assignment,
          title: '오늘 할일을 진행해주세요',
          subtitle: '${widget.todoCount}개의 할일이 남아있어요',
          color: Colors.blue,
          backgroundColor: Colors.blue.shade50,
        ),
      );
    }

    // 4. 냉장고 관리 메시지
    final weekItems = widget.fridgeItems
        .where((item) => item.daysLeft <= 7)
        .length;

    if (weekItems > 0) {
      messages.add(
        _HeaderMessage(
          icon: Icons.kitchen,
          title: '냉장고 관리가 필요해요',
          subtitle: '${weekItems}개 재료의 유통기한을 확인해보세요',
          color: Colors.orange,
          backgroundColor: Colors.orange.shade50,
        ),
      );
    }

    // 5. 기본 환영 메시지 (다른 메시지가 없을 때)
    if (messages.isEmpty) {
      messages.add(
        _HeaderMessage(
          icon: Icons.home,
          title: '안녕하세요! 좋은 하루 보내세요',
          subtitle: '스마트한 냉장고 관리를 시작해보세요',
          color: Colors.blue,
          backgroundColor: Colors.blue.shade50,
        ),
      );
    }

    return messages;
  }

  // ========== 빌드 메서드 ==========

  @override
  Widget build(BuildContext context) {
    final messages = _generateMessages();
    if (messages.isEmpty) return const SizedBox.shrink();

    final currentMessage = messages[_currentMessageIndex % messages.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // 흰색 배경
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: currentMessage.color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentMessage.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  currentMessage.icon,
                  color: currentMessage.color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentMessage.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentMessage.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 진행률 인디케이터 (점들)
              _buildProgressIndicator(messages.length),
            ],
          ),
        ),
      ),
    );
  }

  /// 진행률 인디케이터 빌드 (작은 점들)
  Widget _buildProgressIndicator(int totalMessages) {
    if (totalMessages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalMessages, (index) {
        final isActive = index == _currentMessageIndex;
        return Container(
          margin: const EdgeInsets.only(left: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

/// 헤더 메시지 데이터 클래스
class _HeaderMessage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;

  const _HeaderMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
  });
}
