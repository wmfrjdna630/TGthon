import 'package:flutter/material.dart';

// ---------- 데이터 모델 ----------
class FridgeItem {
  final String name;
  final int daysLeft; // 0 = 오늘, 14 = 2주 후
  FridgeItem(this.name, this.daysLeft);
}

class MenuRec {
  final String title;
  final String needMessage; // 필수 재료 없을 때 문장
  final String goodMessage; // 있으면 더 좋은 재료 문장
  final int minDaysLeft; // 관련 재료 중 가장 임박한 남은일
  final int frequency; // 사용 빈도
  final bool favorite; // 즐겨찾기 여부
  final bool hasAllRequired; // 필수 재료 보유 여부

  MenuRec({
    required this.title,
    required this.needMessage,
    required this.goodMessage,
    required this.minDaysLeft,
    required this.frequency,
    required this.favorite,
    required this.hasAllRequired,
  });
}

// ---------- 페이지 ----------
class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, this.userName = '공육공육공'});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SortMode { expiry, frequency, favorite }

class _HomePageState extends State<HomePage> {
  SortMode _mode = SortMode.expiry;

  // 샘플 메뉴 데이터
  final List<MenuRec> _menus = [
    MenuRec(
      title: '된장찌개',
      needMessage: '애호박, 된장 재료가 꼭 필요해요!',
      goodMessage: '치킨스톡 재료가 있으면 더 좋아요!',
      minDaysLeft: 1,
      frequency: 2,
      favorite: false,
      hasAllRequired: false, // ❗ 필수 재료 부족
    ),
    MenuRec(
      title: '간장계란밥',
      needMessage: '',
      goodMessage: '참기름 재료가 있으면 더 좋아요!',
      minDaysLeft: 6,
      frequency: 5,
      favorite: true,
      hasAllRequired: true, // ✅ 모두 있음
    ),
    MenuRec(
      title: '알리오 파스타',
      needMessage: '파스타면, 마늘 재료가 꼭 필요해요!',
      goodMessage: '파슬리 재료가 있으면 더 좋아요!',
      minDaysLeft: 10,
      frequency: 3,
      favorite: true,
      hasAllRequired: false, // ❗ 부족
    ),
  ];

  List<MenuRec> get _sortedMenus {
    final list = [..._menus];
    switch (_mode) {
      case SortMode.expiry:
        list.sort((a, b) => a.minDaysLeft.compareTo(b.minDaysLeft));
        break;
      case SortMode.frequency:
        list.sort((a, b) => b.frequency.compareTo(a.frequency));
        break;
      case SortMode.favorite:
        list.sort((a, b) {
          if (a.favorite == b.favorite) return a.title.compareTo(b.title);
          return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
        });
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // 상단 초록 배너
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C965),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Hello! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Let's manage your food better today",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // 본문
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildFridgeTimeline(),
                      const SizedBox(height: 24),

                      // 메뉴 추천 섹션
                      _buildMenuRecommendations(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 타임라인 ----------
  Widget _buildFridgeTimeline() {
    final items = <FridgeItem>[
      FridgeItem('계란', 2),
      FridgeItem('김치', 6),
      FridgeItem('버터', 8),
      FridgeItem('양파', 12),
      FridgeItem('마늘', 14),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${widget.userName} 님의 냉장고',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const barHeight = 6.0;
              const totalDays = 14.0;
              const rowGap = 36.0;

              return SizedBox(
                height: rowGap * 3 + 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE74C3C),
                              Color(0xFFF39C12),
                              Color(0xFF2ECC71),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: barHeight + 4,
                      left: 0,
                      child: Text('오늘', style: TextStyle(fontSize: 12)),
                    ),
                    const Positioned(
                      top: barHeight + 4,
                      right: 0,
                      child: Text('2주', style: TextStyle(fontSize: 12)),
                    ),
                    ...items.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final d = item.daysLeft.clamp(0, totalDays).toDouble();
                      final x = (d / totalDays) * width;
                      final left = (x - 24).clamp(0.0, width - 48.0);
                      final rail = idx % 3;
                      final top = 24 + rail * rowGap;
                      return Positioned(
                        left: left,
                        top: top,
                        child: _timelineChip(item.name, item.daysLeft),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _timelineChip(String name, int daysLeft) {
    final bg = _colorForDaysLeft(daysLeft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorForDaysLeft(int daysLeft) {
    final d = daysLeft.clamp(0, 14);
    if (d <= 3) return const Color(0xFFE74C3C);
    if (d <= 7) return const Color(0xFFF39C12);
    return const Color(0xFF2ECC71);
  }

  // ---------- 메뉴 추천 ----------
  Widget _buildMenuRecommendations() {
    const double listHeight = 280; // 필요하면 240~360 등으로 조절

    return Container(
      width: double.infinity, // ⬅️ 냉장고 카드와 동일하게 꽉 채움
      padding: const EdgeInsets.all(16), // ⬅️ 내부 패딩 통일(16)
      decoration: BoxDecoration(
        // ⬅️ 냉장고 카드와 동일한 스타일
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 왼쪽 타이틀 / 오른쪽 버튼들
          Row(
            children: [
              const Text(
                '메뉴 추천',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // 버튼들이 좁은 화면에서도 예쁘게 줄바꿈되도록 Wrap 사용
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sortButton('유통기한순', SortMode.expiry),
                  _sortButton('빈도순', SortMode.frequency),
                  _sortButton('즐겨찾는순', SortMode.favorite),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 리스트만 스크롤되는 영역 (폭 맞춤)
          SizedBox(
            height: listHeight,
            width: double.infinity,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: ListView.builder(
                  key: ValueKey(_mode),
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: _sortedMenus.length,
                  itemBuilder: (context, index) =>
                      _menuCard(_sortedMenus[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortButton(String label, SortMode mode) {
    return OutlinedButton(
      onPressed: () => setState(() => _mode = mode),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Color(0xFFB0BEC5)), // 회색 테두리 고정
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _menuCard(MenuRec m) {
    // 카드 색/테두리 기본값: 재료 여부로 결정
    Color bg;
    Color border;
    if (!m.hasAllRequired) {
      bg = const Color(0xFFFDE0E0); // 연빨강 배경
      border = const Color(0xFFE57373); // 빨간 테두리
    } else {
      bg = const Color(0xFFE0F2E9); // 연초록 배경
      border = const Color(0xFF81C784); // 초록 테두리
    }

    // 상단 아이콘/색상은 정렬 모드별 유지
    IconData leadIcon;
    Color leadColor;
    switch (_mode) {
      case SortMode.expiry:
        leadIcon = m.hasAllRequired
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded;
        leadColor = m.hasAllRequired
            ? const Color(0xFF2E7D32)
            : const Color(0xFFD84315);
        break;
      case SortMode.favorite:
        leadIcon = m.favorite ? Icons.favorite : Icons.favorite_border;
        leadColor = const Color(0xFF2E7D32);
        break;
      case SortMode.frequency:
        leadIcon = Icons.trending_up_rounded;
        leadColor = const Color(0xFF546E7A);
        break;
    }

    // 내용 줄 구성: 부족하면 2줄, 있으면 1줄
    final List<Widget> lines = [];
    if (!m.hasAllRequired) {
      lines.add(
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD84315),
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                m.needMessage,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD84315)),
              ),
            ),
          ],
        ),
      );
      lines.add(const SizedBox(height: 2));
    }
    lines.add(
      Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              m.goodMessage,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(leadIcon, size: 18, color: leadColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...lines,
        ],
      ),
    );
  }

  // ---------- Quick Actions ----------
  static Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.add, color: Colors.green, size: 20),
              SizedBox(width: 6),
              Text(
                'Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Expanded(
                child: _QuickActionCard(icon: Icons.add, label: 'Add Item'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.camera_alt,
                  label: 'Scan Receipt',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- 퀵 액션 카드 ----------
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickActionCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE8CC),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 75,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
