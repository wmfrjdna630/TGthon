import 'package:flutter/material.dart';
import '../../widgets/recipe_card.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});
  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _chipCtrl = ScrollController();

  String selectedFilter = 'Can make now';

  // 샘플 데이터
  final List<Map<String, dynamic>> recipes = [
    {
      'title': 'Fresh Garden Salad',
      'timeMin': 10,
      'servings': 1,
      'difficulty': 'easy',
      'have': 3,
      'need': 4,
      'tags': ['quick', 'vegetarian'],
    },
    {
      'title': 'Vegetable Soup',
      'timeMin': 45,
      'servings': 4,
      'difficulty': 'easy',
      'have': 5,
      'need': 7,
      'tags': ['vegetarian'],
    },
    {
      'title': 'Creamy Chicken Pasta',
      'timeMin': 25,
      'servings': 2,
      'difficulty': 'medium',
      'have': 6,
      'need': 8,
      'tags': ['quick'],
    },
  ];

  bool _canMakeNow(Map r) => (r['have'] as int) >= (r['need'] as int);
  bool _almostReady(Map r) => (r['need'] as int) - (r['have'] as int) <= 2;

  int get canMakeCount => recipes.where(_canMakeNow).length;
  int get almostCount => recipes.where(_almostReady).length;
  int get quickCount =>
      recipes.where((r) => (r['tags'] as List).contains('quick')).length;
  int get vegetarianCount =>
      recipes.where((r) => (r['tags'] as List).contains('vegetarian')).length;

  List<Map<String, dynamic>> get filtered {
    switch (selectedFilter) {
      case 'Can make now':
        return recipes.where(_canMakeNow).toList();
      case 'Almost ready':
        return recipes.where(_almostReady).toList();
      case 'Quick meals':
        return recipes
            .where((r) => (r['tags'] as List).contains('quick'))
            .toList();
      case 'Vegetarian':
        return recipes
            .where((r) => (r['tags'] as List).contains('vegetarian'))
            .toList();
      default:
        return recipes;
    }
  }

  @override
  void initState() {
    super.initState();
    _chipCtrl.addListener(() => setState(() {})); // 칩 스크롤 시 썸 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 첫 프레임 후 썸 계산
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _chipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // 상단 초록 배너 (FridgePage와 동일 톤, 중앙 정렬)
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.soup_kitchen, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Recipes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _readyLine(
                      readyCount: canMakeCount,
                      almostCount: almostCount,
                    ),
                  ],
                ),
              ),

              // 본문
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // 검색창 (FridgePage 스타일)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  focusNode: _focusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Search recipes...',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF34C965),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F4F4),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 필터 칩 (여백 강제X, 실제 컨텐츠 길이만큼만)
                      _buildFilterChips(),

                      const SizedBox(height: 8),

                      // 칩 가로 스크롤 진행바 (트랙 고정폭, 썸 길이 = 화면/전체)
                      _buildChipScrollbar(),

                      const SizedBox(height: 12),

                      // 레시피 리스트 (부드러운 전환 + 기본 스크롤바 숨김)
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, .06),
                              end: Offset.zero,
                            ).animate(anim);
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: ScrollConfiguration(
                            key: ValueKey(selectedFilter),
                            behavior: ScrollConfiguration.of(
                              context,
                            ).copyWith(scrollbars: false),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final r = filtered[i];
                                return RecipeCard(
                                  title: r['title'],
                                  time: '${r['timeMin']}m',
                                  servings: r['servings'],
                                  difficulty: r['difficulty'],
                                  ingredientsHave: r['have'],
                                  ingredientsTotal: r['need'],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 라인: ☆ X ready to cook • Y almost ready
  Widget _readyLine({required int readyCount, required int almostCount}) {
    return Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.star_border, size: 16, color: Colors.white),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: '$readyCount ready to cook',
            style: const TextStyle(color: Colors.white),
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: 12),
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _Dot(color: Color(0xFFF5A623), rightGap: 3),
          ),
          TextSpan(
            text: ' $almostCount almost ready',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // 필터 칩 + 뱃지
  Widget _buildFilterChips() {
    final labels = [
      'Can make now',
      'Almost ready',
      'Quick meals',
      'Vegetarian',
    ];
    final counts = {
      'Can make now': canMakeCount,
      'Almost ready': almostCount,
      'Quick meals': quickCount,
      'Vegetarian': vegetarianCount,
    };
    const textStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 12);

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.horizontal) setState(() {});
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: _chipCtrl,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(labels.length, (i) {
              final label = labels[i];
              final selected = selectedFilter == label;
              final count = counts[label] ?? 0;

              return Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedFilter = label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEAF7EF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF34C965)
                            : const Color(0xFFE0E0E0),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: textStyle.copyWith(
                            color: selected
                                ? const Color(0xFF34C965)
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF34C965)
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // 가로 진행바(트랙=화면폭, 썸=화면/전체, 드래그/탭/버튼 동기화)
  Widget _buildChipScrollbar() {
    const double kMinThumb = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double W_track = constraints.maxWidth;
        double W_thumb = W_track;
        double thumbLeft = 0;
        bool canScroll = false;

        if (_chipCtrl.hasClients) {
          final pos = _chipCtrl.position;
          final double W_view = pos.viewportDimension;
          final double max = pos.maxScrollExtent;
          final double W_total = max + W_view;
          canScroll = max > 0;

          if (W_total > W_view) {
            W_thumb = (W_track * (W_view / W_total)).clamp(kMinThumb, W_track);
            final double denom = (W_total - W_view);
            final double frac = denom > 0
                ? (pos.pixels / denom).clamp(0.0, 1.0)
                : 0.0;
            thumbLeft = (W_track - W_thumb) * frac;
          } else {
            W_thumb = W_track;
            thumbLeft = 0;
          }
        }

        void scrollBy(double delta) {
          if (!_chipCtrl.hasClients) return;
          final target = (_chipCtrl.offset + delta).clamp(
            0.0,
            _chipCtrl.position.maxScrollExtent,
          );
          _chipCtrl.animateTo(
            target,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }

        void jumpByThumbLeft(double left) {
          if (!_chipCtrl.hasClients) return;
          final pos = _chipCtrl.position;
          final double W_view = pos.viewportDimension;
          final double W_total = pos.maxScrollExtent + W_view;
          final double range = (W_track - W_thumb);
          if (range <= 0) return;
          final double frac = (left / range).clamp(0.0, 1.0);
          final double target = frac * (W_total - W_view);
          _chipCtrl.jumpTo(target);
        }

        return Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints.tightFor(width: 40, height: 36),
              onPressed: canScroll
                  ? () => scrollBy(-(_chipCtrl.position.viewportDimension / 2))
                  : null,
              icon: const Icon(Icons.arrow_left, color: Colors.grey, size: 25),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (d) {
                  if (!_chipCtrl.hasClients) return;
                  final pos = _chipCtrl.position;
                  final double W_view = pos.viewportDimension;
                  final double W_total = pos.maxScrollExtent + W_view;
                  final double range = (W_track - W_thumb);
                  if (W_total <= W_view || range <= 0) return;

                  final double deltaOffset =
                      d.delta.dx * ((W_total - W_view) / range);
                  final double target = (_chipCtrl.offset + deltaOffset).clamp(
                    0.0,
                    pos.maxScrollExtent,
                  );
                  _chipCtrl.jumpTo(target);
                },
                onTapDown: (d) =>
                    jumpByThumbLeft(d.localPosition.dx - W_thumb / 2),
                child: SizedBox(
                  height: 12,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Positioned(
                        left: thumbLeft,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: W_thumb,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints.tightFor(width: 40, height: 36),
              onPressed: canScroll
                  ? () => scrollBy((_chipCtrl.position.viewportDimension / 2))
                  : null,
              icon: const Icon(Icons.arrow_right, color: Colors.grey, size: 25),
            ),
          ],
        );
      },
    );
  }
}

// 작은 도트
class _Dot extends StatelessWidget {
  final Color color;
  final double rightGap;
  const _Dot({required this.color, this.rightGap = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: EdgeInsets.only(right: rightGap),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
