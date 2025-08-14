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

enum TimeFilter { week, biweek, month }

class _HomePageState extends State<HomePage> {
  SortMode _mode = SortMode.expiry;
  TimeFilter _timeFilter = TimeFilter.biweek;

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
      minDaysLeft: 2,
      frequency: 5,
      favorite: true,
      hasAllRequired: true, // ✅ 모두 있음
    ),
    MenuRec(
      title: '김치볶음밥',
      needMessage: '',
      goodMessage: '베이컨, 햄이 있으면 더 맛있어요!',
      minDaysLeft: 6,
      frequency: 4,
      favorite: true,
      hasAllRequired: true, // ✅ 김치 있음
    ),
    MenuRec(
      title: '버터스크램블',
      needMessage: '',
      goodMessage: '체다치즈, 파슬리가 있으면 완벽해요!',
      minDaysLeft: 2,
      frequency: 3,
      favorite: false,
      hasAllRequired: true, // ✅ 계란, 버터 있음
    ),
    MenuRec(
      title: '양파볶음',
      needMessage: '',
      goodMessage: '간장, 설탕이 있으면 더 달콤해요!',
      minDaysLeft: 12,
      frequency: 2,
      favorite: false,
      hasAllRequired: true, // ✅ 양파 있음
    ),
    MenuRec(
      title: '마늘볶음밥',
      needMessage: '',
      goodMessage: '햄, 당근이 있으면 더 푸짐해요!',
      minDaysLeft: 14,
      frequency: 3,
      favorite: false,
      hasAllRequired: true, // ✅ 마늘 있음
    ),
    MenuRec(
      title: '알리오 파스타',
      needMessage: '파스타면, 올리브오일이 꼭 필요해요!',
      goodMessage: '파슬리, 치즈가 있으면 더 좋아요!',
      minDaysLeft: 14,
      frequency: 3,
      favorite: true,
      hasAllRequired: false, // ❗ 파스타면 부족
    ),
    MenuRec(
      title: '치즈토스트',
      needMessage: '식빵이 꼭 필요해요!',
      goodMessage: '토마토, 햄이 있으면 더 풍성해요!',
      minDaysLeft: 25,
      frequency: 4,
      favorite: false,
      hasAllRequired: false, // ❗ 식빵 부족
    ),
    MenuRec(
      title: '감자볶음',
      needMessage: '',
      goodMessage: '양파, 당근이 있으면 더 맛있어요!',
      minDaysLeft: 28,
      frequency: 2,
      favorite: false,
      hasAllRequired: true, // ✅ 감자 있음
    ),
    MenuRec(
      title: '스크램블 에그',
      needMessage: '',
      goodMessage: '치즈, 허브가 있으면 고급스러워요!',
      minDaysLeft: 2,
      frequency: 6,
      favorite: true,
      hasAllRequired: true, // ✅ 계란 있음
    ),
    MenuRec(
      title: '우유 시리얼',
      needMessage: '시리얼이 꼭 필요해요!',
      goodMessage: '과일, 견과류가 있으면 영양만점!',
      minDaysLeft: 18,
      frequency: 7,
      favorite: false,
      hasAllRequired: false, // ❗ 시리얼 부족
    ),
    MenuRec(
      title: '계란후라이',
      needMessage: '',
      goodMessage: '토스트, 샐러드가 있으면 완벽한 한 끼!',
      minDaysLeft: 2,
      frequency: 8,
      favorite: true,
      hasAllRequired: true, // ✅ 계란 있음
    ),
  ];

  // 샘플 냉장고 아이템
  final List<FridgeItem> _allFridgeItems = [
    FridgeItem('계란', 2),
    FridgeItem('김치', 6),
    FridgeItem('버터', 8),
    FridgeItem('양파', 12),
    FridgeItem('마늘', 14),
    FridgeItem('우유', 18),
    FridgeItem('치즈', 25),
    FridgeItem('감자', 28),
  ];

  int get _maxDaysForFilter {
    switch (_timeFilter) {
      case TimeFilter.week:
        return 7;
      case TimeFilter.biweek:
        return 14;
      case TimeFilter.month:
        return 30;
    }
  }

  String get _filterLabel {
    switch (_timeFilter) {
      case TimeFilter.week:
        return '1주';
      case TimeFilter.biweek:
        return '2주';
      case TimeFilter.month:
        return '1개월';
    }
  }

  List<FridgeItem> get _filteredFridgeItems {
    return _allFridgeItems
        .where((item) => item.daysLeft <= _maxDaysForFilter)
        .toList();
  }

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
                const SizedBox(height: 16),
                _buildTopExpiryBar(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildFridgeTimeline(),
                      const SizedBox(height: 24),
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

  // ---------- 상단 유통기한 바 ----------
  Widget _buildTopExpiryBar() {
    final items = _allFridgeItems;
    final dangerCount = items.where((item) => item.daysLeft <= 3).length;
    final warningCount = items
        .where((item) => item.daysLeft > 3 && item.daysLeft <= 7)
        .length;
    final safeCount = items.where((item) => item.daysLeft > 7).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _topRiskIndicator(
            Icons.dangerous,
            dangerCount.toString(),
            const Color(0xFFE74C3C),
          ),
          _topRiskIndicator(
            Icons.warning,
            warningCount.toString(),
            const Color(0xFFF39C12),
          ),
          _topRiskIndicator(
            Icons.check_circle,
            safeCount.toString(),
            const Color(0xFF2ECC71),
          ),
        ],
      ),
    );
  }

  Widget _topRiskIndicator(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ---------- 검색 바 ----------
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: '메뉴나 재료를 검색하세요...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF34C965),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  icon: Icons.add,
                  label: 'Add Item',
                  color: const Color(0xFFF5E6D3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionButton(
                  icon: Icons.camera_alt,
                  label: 'Scan Receipt',
                  color: const Color(0xFFF5E6D3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 빠른 액션 ----------

  // ---------- 타임라인 ----------
  Widget _buildFridgeTimeline() {
    final items = _filteredFridgeItems;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.userName} 님의 냉장고',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              _buildTimeFilterChips(),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const barHeight = 6.0;
              final totalDays = _maxDaysForFilter.toDouble();
              const rowGap = 36.0;
              const labelGap = 22.0;

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
                      top: -labelGap,
                      left: 0,
                      child: Text('오늘', style: TextStyle(fontSize: 12)),
                    ),
                    Positioned(
                      top: -labelGap,
                      right: 0,
                      child: Text(
                        _filterLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
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

  Widget _buildTimeFilterChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TimeFilter.values.map((filter) {
        final isSelected = _timeFilter == filter;
        String label;
        switch (filter) {
          case TimeFilter.week:
            label = '1주';
            break;
          case TimeFilter.biweek:
            label = '2주';
            break;
          case TimeFilter.month:
            label = '1개월';
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => setState(() => _timeFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF34C965) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    if (daysLeft <= 3) return const Color(0xFFE74C3C);
    if (daysLeft <= 7) return const Color(0xFFF39C12);
    return const Color(0xFF2ECC71);
  }

  // ---------- 메뉴 추천 ----------
  Widget _buildMenuRecommendations() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '메뉴 추천',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildSortChips(),
            ],
          ),
          const SizedBox(height: 16),
          ..._sortedMenus.map((menu) => _buildMenuCard(menu)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(MenuRec menu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: menu.hasAllRequired
            ? const Color(0xFFE8F5E8)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: menu.hasAllRequired
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFF9800),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  menu.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (menu.favorite)
                const Icon(Icons.favorite, color: Colors.red, size: 20),
            ],
          ),
          if (menu.needMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: menu.hasAllRequired ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    menu.needMessage.isEmpty
                        ? '모든 재료가 준비되어 있어요!'
                        : menu.needMessage,
                    style: TextStyle(
                      color: menu.hasAllRequired
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (menu.goodMessage.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    menu.goodMessage,
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sortChip('유통기한순', SortMode.expiry),
        const SizedBox(width: 4),
        _sortChip('빈도순', SortMode.frequency),
        const SizedBox(width: 4),
        _sortChip('즐겨찾는순', SortMode.favorite),
      ],
    );
  }

  Widget _sortChip(String label, SortMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.blue) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.blue[800] : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
