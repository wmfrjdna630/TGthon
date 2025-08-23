// lib/screens/recipes/recipes_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/common/blue_header.dart';
import '../../widgets/recipes/recipe_card.dart';
import '../../data/recipe_repository.dart';
import '../../data/remote/recipe_api.dart';
import '../../models/recipe.dart';
import '../../models/menu_rec.dart';
import '../../widgets/common/compact_search_bar.dart';

// ==== 냉장고 & 랭커 ====
import '../../data/remote/fridge_repository.dart';
import '../../models/fridge_item.dart';
import '../../services/recipe_ranker.dart';

/// 정렬 모드 (홈과 동일한 의미)
enum RecipeSortMode { expiry, frequency, favorite }

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});
  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  // ===== 상태 =====
  String _selectedCategory = '전체';
  RecipeSortMode _sortMode = RecipeSortMode.expiry;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final RecipeRepository _repository;

  List<Recipe> _allRecipes = [];
  List<MenuRec> _allMenus = [];     // 원본 후보(개수 유지)
  List<MenuRec> _rankedMenus = [];  // 랭커 결과(기본 순서)
  Map<String, int> _rankPos = {};   // title -> 랭크 위치(작을수록 우선)
  bool _isLoading = true;

  // 임박 기준 & 페이지 사이즈
  static const int _expiryThresholdDays = 7;
  static const int _pageSize = 10;

  // 전역 컷: "필수 재료 개수 < 15" 유지
  static const int _maxRequiredIngredients = 15;

  int _currentPage = 1;
  Timer? _debounce;

  // 냉장고 실시간
  final FridgeRemoteRepository _fridgeRepo = FridgeRemoteRepository();
  List<FridgeItem> _fridgeItems = [];
  StreamSubscription<List<FridgeItem>>? _fridgeSub;

  // ===== 파생 =====

  /// ▶︎ [핵심 수정] 지금 화면 모드(정렬/검색/총재료<15)를 그대로 적용한 “표시 대상 메뉴” 집합
  /// - 카테고리 선택만 제외(칩 카운트에 쓰기 위함)
  List<MenuRec> _menusForCounts() {
    if (_isLoading) return const [];

    // 1) 총재료<15 컷과 타이틀 인덱스
    final byTitle = {for (final r in _allRecipes) r.title: r};
    final allowedTitles = _allRecipes
        .where((r) => r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients)
        .map((r) => r.title)
        .toSet();

    // 2) 랭커 결과에서 허용 타이틀만
    List<MenuRec> base = _rankedMenus.where((m) => allowedTitles.contains(m.title)).toList();

    // 3) 정렬 모드별 ‘필터’를 동일 적용 (순서는 중요치 않음, 카운트 용도)
    switch (_sortMode) {
      case RecipeSortMode.expiry:
        base = base.where((m) => m.minDaysLeft < _expiryThresholdDays).toList();
        break;
      case RecipeSortMode.frequency:
        base = base.where((m) => (byTitle[m.title]?.ingredientsHave ?? 0) > 0).toList();
        break;
      case RecipeSortMode.favorite:
        base = base.where((m) => m.favorite).toList();
        break;
    }

    // 4) 검색 필터도 동일 적용
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      base = base.where((m) {
        final r = byTitle[m.title];
        if (r == null) return false;
        final hitTitle = r.title.toLowerCase().contains(q);
        final hitTag = r.tags.any((t) => t.toLowerCase().contains(q));
        return hitTitle || hitTag;
      }).toList();
    }

    return base;
  }

  /// ▶︎ [핵심 수정] 칩 카운트 = 현재 화면 모드(정렬/검색/총재료<15)에서의 개수
  Map<String, int> get _categoryCounts {
    final menus = _menusForCounts();
    final byTitle = {for (final r in _allRecipes) r.title: r};

    int total = 0, rice = 0, soup = 0, side = 0, dessert = 0;
    for (final m in menus) {
      final r = byTitle[m.title];
      if (r == null) continue;
      total++;
      final tagsLower = r.tags.map((t) => t.trim().toLowerCase()).toSet();
      if (tagsLower.contains('밥')) rice++;
      if (tagsLower.contains('국&찌개')) soup++;
      if (tagsLower.contains('반찬')) side++;
      if (tagsLower.contains('후식')) dessert++;
    }

    return <String, int>{
      '전체': total,
      '밥': rice,
      '국&찌개': soup,
      '반찬': side,
      '후식': dessert,
    };
  }

  int get _canMakeCount => _allRecipes
      .where((r) => r.ingredientsTotal < _maxRequiredIngredients)
      .where((r) => r.canMakeNow)
      .length;

  int get _almostReadyCount => _allRecipes
      .where((r) => r.ingredientsTotal < _maxRequiredIngredients)
      .where((r) => r.isAlmostReady)
      .length;

  int get _totalPages {
    final total = _displayListUnpaged.length;
    return (total / _pageSize).ceil().clamp(1, 9999);
    // 이제 칩의 '전체' 숫자 == _displayListUnpaged.length 와 동일한 집합 크기 느낌으로 보일 거야
  }

  // ===== 라이프사이클 =====
  @override
  void initState() {
    super.initState();

    // API 키: dart-define 우선, 없으면 sample
    const defineKey = String.fromEnvironment('FOOD_API_KEY');
    final keyId = defineKey.isNotEmpty ? defineKey : 'sample';

    _repository = RecipeRepository(
      api: RecipeApi(
        base: 'https://openapi.foodsafetykorea.go.kr',
        keyId: keyId,
        serviceId: 'COOKRCP01',
      ),
    );

    _initFridgeAndLoad();
  }

  @override
  void dispose() {
    _clearAllSnackBars();
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _fridgeSub?.cancel();
    super.dispose();
  }

  // ===== 냉장고 초기화 + 실시간 반영 + 로드 =====
  Future<void> _initFridgeAndLoad() async {
    try {
      _fridgeItems = await _fridgeRepo.getFridgeItems();
    } catch (_) {/* ignore */}
    _fridgeSub?.cancel();
    _fridgeSub = _fridgeRepo.watchFridgeItems().listen((items) {
      _fridgeItems = items;
      _loadAll(); // 냉장고 변경 시 즉시 반영
    });
    await _loadAll();
  }

  // 냉장고 → include 문자열(임박 상위 N개) — API 후보만 좁힘(개수는 유지)
  String? _buildIncludeFromFridge({int limit = 8}) {
    if (_fridgeItems.isEmpty) return null;
    final sorted = [..._fridgeItems]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final names = sorted
        .map((e) => e.name.trim())
        .where((s) => s.isNotEmpty)
        .take(limit)
        .toList();
    return names.isEmpty ? null : names.join(',');
  }

  // 냉장고만을 기준으로 UI 표시용 보유재료 수 산출
  int _haveCountFromFridge(Recipe r) {
    final text = (r.title + ' ' + (r.tags.isEmpty ? '' : r.tags.join(' '))).toLowerCase();
    final seen = <String>{};
    int have = 0;
    for (final f in _fridgeItems) {
      final n = f.name.trim().toLowerCase();
      if (n.isEmpty || seen.contains(n)) continue;
      if (text.contains(n)) {
        have++;
        seen.add(n);
      }
    }
    return have;
  }

  // =========================
  // 데이터 로드 (개수 유지: fetchAll* 사용)
  // =========================
  Future<void> _loadAll() async {
    try {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });

      final keyword = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      final dish = _mapCategoryToRcpPat2(_selectedCategory);
      final includeParam = _buildIncludeFromFridge(limit: 8);

      final recipes = await _repository.fetchAllRecipes(
        keyword: keyword,
        dishType: dish,
        include: includeParam,
        pageSize: 100,
      );
      final menus = await _repository.fetchAllMenus(
        keyword: keyword,
        dishType: dish,
        include: includeParam,
        pageSize: 100,
      );

      // 표시용 보유재료 수치는 무조건 냉장고 기준으로 재산출
      final rebasedRecipes = <Recipe>[];
      for (final r in recipes) {
        final have = _haveCountFromFridge(r);
        rebasedRecipes.add(
          r.copyWith(
            ingredientsHave: (r.ingredientsTotal > 0)
                ? have.clamp(0, r.ingredientsTotal)
                : have,
          ),
        );
      }

      // 랭커 + have==0 후순위
      final recipeIndex = {for (final r in rebasedRecipes) r.title: r};
      final ranker = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );
      final ranked = ranker.sortByPriority(
        menus: menus,
        recipeByTitle: recipeIndex,
      );

      final withHave = <MenuRec>[];
      final withoutHave = <MenuRec>[];
      for (final m in ranked) {
        final have = recipeIndex[m.title]?.ingredientsHave ?? 0;
        (have > 0 ? withHave : withoutHave).add(m);
      }
      final rankedFinal = [...withHave, ...withoutHave];

      final pos = <String, int>{};
      for (int i = 0; i < rankedFinal.length; i++) {
        pos[rankedFinal[i].title] = i;
      }

      if (!mounted) return;
      setState(() {
        _allRecipes = rebasedRecipes; // 카테고리/검색/페이지네이션 대상
        _allMenus = menus;            // 원본 후보 보존
        _rankedMenus = rankedFinal;   // 기본 순서
        _rankPos = pos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('레시피를 불러오는데 실패했습니다: $e');
    }
  }

  // =========================
  // 정렬/필터 후 리스트 (페이지네이션 전)
  // =========================
  List<Recipe> get _displayListUnpaged {
    if (_isLoading) return const [];

    final byTitleAll = {for (final r in _allRecipes) r.title: r};

    // 전역 컷: 총 재료 < 15 인 레시피만 허용
    final allowedTitles = _allRecipes
        .where((r) => r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients)
        .map((r) => r.title)
        .toSet();

    // 기본 집합: 랭커 결과 순서(이미 have==0은 뒤)
    List<MenuRec> base = _rankedMenus.where((m) => allowedTitles.contains(m.title)).toList();

    // 모드별 필터/보조정렬
    switch (_sortMode) {
      case RecipeSortMode.expiry:
        base = base.where((m) => m.minDaysLeft < _expiryThresholdDays).toList();
        break;

      case RecipeSortMode.frequency:
        int missingByTitle(String title) {
          final r = byTitleAll[title];
          if (r == null) return 999;
          final miss = r.ingredientsTotal - r.ingredientsHave;
          return miss < 0 ? 0 : miss;
        }
        base = base
            .where((m) => (byTitleAll[m.title]?.ingredientsHave ?? 0) > 0)
            .toList();
        base.sort((a, b) {
          final am = missingByTitle(a.title);
          final bm = missingByTitle(b.title);
          if (am != bm) return am.compareTo(bm);
          return (_rankPos[a.title] ?? 1 << 30).compareTo(_rankPos[b.title] ?? 1 << 30);
        });
        break;

      case RecipeSortMode.favorite:
        base = base.where((m) => m.favorite).toList();
        break;
    }

    // MenuRec → Recipe 매핑
    List<Recipe> ordered = [];
    for (final m in base) {
      final r = byTitleAll[m.title];
      if (r != null) ordered.add(r);
    }

    // 카테고리 필터
    if (_selectedCategory != '전체') {
      final want = _selectedCategory;
      ordered = ordered.where((r) {
        final tagsLower = r.tags.map((t) => t.trim().toLowerCase()).toSet();
        switch (want) {
          case '밥':
            return tagsLower.contains('밥');
          case '국&찌개':
            return tagsLower.contains('국&찌개');
          case '반찬':
            return tagsLower.contains('반찬');
          case '후식':
            return tagsLower.contains('후식');
          default:
            return true;
        }
      }).toList();
    }

    // 검색(제목/태그)
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      ordered = ordered.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return ordered;
  }

  // 실제 그릴 페이지 조각
  List<Recipe> get _displayPage {
    final list = _displayListUnpaged;
    if (list.isEmpty) return const [];
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, list.length);
    if (start >= list.length) return const [];
    return list.sublist(start, end);
  }

  // ======= UI (원본 유지) =======
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              BlueHeader.recipes(
                readyCount: _canMakeCount,
                almostCount: _almostReadyCount,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      CompactSearchBar(
                        controller: _searchController,
                        onChanged: _onSearchChangedDebounced,
                        focusNode: _focusNode,
                      ),
                      const SizedBox(height: 16),
                      _CategoryChips(
                        selected: _selectedCategory,
                        counts: _categoryCounts,
                        onChanged: (c) async {
                          setState(() {
                            _selectedCategory = c;
                            _isLoading = true;
                            _currentPage = 1;
                          });
                          await Future.delayed(const Duration(milliseconds: 150));
                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                          // 필요시 API 필터로도 반영하려면: await _loadAll();
                        },
                      ),
                      const SizedBox(height: 8),
                      _SortChips(
                        current: _sortMode,
                        onChanged: (m) => setState(() {
                          _sortMode = m;
                          _currentPage = 1;
                        }),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _buildList()),
                      _buildPaginator(),
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

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final list = _displayPage;
    if (list.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (_, i) => RecipeCard(
        recipe: list[i],
        onTap: () => _showInfoSnackBar('${list[i].title} 상세보기'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '조건에 맞는 레시피가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '필터를 바꾸거나 다른 키워드로 검색해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginator() {
    final total = _totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PgBtn(
            icon: Icons.chevron_left,
            onTap: _currentPage > 1 ? () => setState(() => _currentPage -= 1) : null,
          ),
          const SizedBox(width: 8),
          Text('$_currentPage / $total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _PgBtn(
            icon: Icons.chevron_right,
            onTap: _currentPage < total ? () => setState(() => _currentPage += 1) : null,
          ),
        ],
      ),
    );
  }

  // ===== 스낵바 =====
  void _clearAllSnackBars() {
    if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
  }

  void _showSnackBar(String msg, Color c, {int ms = 1500}) {
    _clearAllSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: c,
        duration: Duration(milliseconds: ms),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String m) => _showSnackBar(m, Colors.red, ms: 2000);
  void _showInfoSnackBar(String m) =>
      _showSnackBar(m, const Color.fromARGB(255, 30, 0, 255));

  String? _mapCategoryToRcpPat2(String ui) {
    switch (ui) {
      case '전체':
        return null;
      case '밥':
        return '밥';
      case '국&찌개':
        return '국&찌개';
      case '반찬':
        return '반찬';
      case '후식':
        return '후식';
      default:
        return null;
    }
  }

  void _onSearchChangedDebounced(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _loadAll();
    });
  }
}

// ===== 카테고리 칩 =====
class _CategoryChips extends StatelessWidget {
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onChanged;

  const _CategoryChips({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = ['전체', '밥', '국&찌개', '반찬', '후식'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((label) {
          final isSel = selected == label;
          final count = counts[label] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color.fromARGB(255, 30, 0, 255) : const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSel ? const Color.fromARGB(255, 30, 0, 255) : Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ===== 정렬 칩 =====
class _SortChips extends StatelessWidget {
  final RecipeSortMode current;
  final ValueChanged<RecipeSortMode> onChanged;

  const _SortChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, RecipeSortMode m) => GestureDetector(
      onTap: () => onChanged(m),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: current == m ? const Color.fromARGB(255, 30, 0, 255) : const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: current == m ? Colors.white : Colors.black87,
            fontWeight: current == m ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );

    return Row(
      children: [
        chip('유통기한순', RecipeSortMode.expiry),
        chip('빈도순', RecipeSortMode.frequency),
        chip('즐겨찾는순', RecipeSortMode.favorite),
      ],
    );
  }
}

// ===== 페이지네이션 버튼 =====
class _PgBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PgBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.black12 : Colors.black12.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black87 : Colors.black38,
        ),
      ),
    );
  }
}
