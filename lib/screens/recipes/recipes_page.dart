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

// ==== [추가] 냉장고 & 랭커 ====
import '../../data/remote/fridge_repository.dart';
import '../../models/fridge_item.dart';
import '../../services/recipe_ranker.dart';

/// 정렬 모드 (홈과 동일한 의미)
enum RecipeSortMode { expiry, frequency, favorite }

/// 레시피 페이지
/// - 전체 로드(fetchAll) 후 클라이언트에서 10개씩 페이지네이션
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
  List<MenuRec> _allMenus = []; // 정렬/필터용 메타(유통기한/즐겨찾기 등)
  bool _isLoading = true;

  // 임박 기준 & 페이지 사이즈
  static const int _expiryThresholdDays = 7; // (UI 텍스트용 그대로 보존)
  static const int _pageSize = 10;

  // "필수 재료 개수 < N" 글로벌 필터(카테고리/리스트 공통 적용)
  static const int _maxRequiredIngredients = 15; // 미만 조건
  // 페이지네이션 상태
  int _currentPage = 1;

  // 검색 디바운스
  Timer? _debounce;

  // ==== [추가] 냉장고 실시간 + 랭킹 캐시 ====
  final FridgeRemoteRepository _fridgeRepo = FridgeRemoteRepository();
  List<FridgeItem> _fridgeItems = [];
  StreamSubscription<List<FridgeItem>>? _fridgeSub;

  // 홈과 동일한 랭킹 결과를 재사용하기 위한 캐시
  List<MenuRec> _rankedMenus = [];
  Map<String, int> _rankPos = {}; // title -> 랭킹 위치(작을수록 우선)

  // ===== 파생 =====
  Map<String, int> get _categoryCounts {
    final subset = _allRecipes
        .where((r) => r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients)
        .toList();

    final base = <String, int>{'전체': subset.length, '밥': 0, '국&찌개': 0, '반찬': 0, '후식': 0};

    for (final r in subset) {
      final tagsLower = r.tags.map((t) => t.trim().toLowerCase()).toSet();
      if (tagsLower.contains('밥')) base['밥'] = (base['밥'] ?? 0) + 1;
      if (tagsLower.contains('국&찌개')) base['국&찌개'] = (base['국&찌개'] ?? 0) + 1;
      if (tagsLower.contains('반찬')) base['반찬'] = (base['반찬'] ?? 0) + 1;
      if (tagsLower.contains('후식')) base['후식'] = (base['후식'] ?? 0) + 1;
    }
    return base;
  }

  int get _canMakeCount => _allRecipes.where((r) => r.canMakeNow).length;
  int get _almostReadyCount => _allRecipes.where((r) => r.isAlmostReady).length;

  int get _totalPages {
    final total = _displayListUnpaged.length;
    return (total / _pageSize).ceil().clamp(1, 9999);
  }

  // ===== 라이프사이클 =====
  @override
  void initState() {
    super.initState();
    _repository = RecipeRepository(
      api: const RecipeApi(
        base: 'https://openapi.foodsafetykorea.go.kr',
        keyId: 'sample', // 개발 중 쿼터 문제 회피. 빌드 시 dart-define로 교체 가능.
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

  // =========================
  // [추가] 냉장고 초기화 + 실시간 반영 + 로드
  // =========================
  Future<void> _initFridgeAndLoad() async {
    try {
      final first = await _fridgeRepo.getFridgeItems();
      _fridgeItems = first;
    } catch (_) {/* 무시 */}

    _fridgeSub?.cancel();
    _fridgeSub = _fridgeRepo.watchFridgeItems().listen((items) {
      _fridgeItems = items;
      _loadAll(); // 냉장고 변경 시 즉시 재랭킹/재조회
    });

    await _loadAll();
  }

  // =========================
  // 데이터 로드 (+ 홈과 동일 랭커 적용)
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

      // 냉장고 임박 재료 상위 N개를 include로 (홈과 동일한 데이터 기반을 맞추기 위함)
      final String? includeParam = _buildIncludeFromFridge(limit: 8);

      // 전체 로드
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

      // 홈과 같은 랭커 적용
      final recipeIndex = <String, Recipe>{for (final r in recipes) r.title: r};
      final ranker = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );
      final ranked = ranker.sortByPriority(
        menus: menus,
        recipeByTitle: recipeIndex,
      );

      // 랭킹 위치 맵(타 정렬의 tie-breaker로 사용)
      final pos = <String, int>{};
      for (int i = 0; i < ranked.length; i++) {
        pos[ranked[i].title] = i;
      }

      if (!mounted) return;
      setState(() {
        _allRecipes = recipes;
        _allMenus = menus;
        _rankedMenus = ranked;
        _rankPos = pos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('레시피를 불러오는데 실패했습니다: $e');
    }
  }

  // 냉장고 → include 문자열
  String? _buildIncludeFromFridge({int limit = 8}) {
    if (_fridgeItems.isEmpty) return null;
    final sorted = [..._fridgeItems]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final names = sorted.map((e) => e.name.trim()).where((s) => s.isNotEmpty).take(limit).toList();
    return names.isEmpty ? null : names.join(',');
  }

  // =========================
  // 정렬/필터 후 리스트 (페이지네이션 전)
  //  -> 홈과 동일 랭킹을 1순위로 사용하고,
  //     기존 모드별 기준은 "필터/보조 정렬"로만 사용
  // =========================
  List<Recipe> get _displayListUnpaged {
    if (_isLoading) return const [];

    final byTitleAll = {for (final r in _allRecipes) r.title: r};
    final allowedTitles = _allRecipes
        .where((r) => r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients)
        .map((r) => r.title)
        .toSet();

    // 기본 집합은 "홈 랭킹 순서"를 기준으로 맞춘다.
    List<MenuRec> base = _rankedMenus.where((m) => allowedTitles.contains(m.title)).toList();

    // 모드별 필터/보조정렬만 적용(기본 순서는 랭킹 유지)
    switch (_sortMode) {
      case RecipeSortMode.expiry:
        // 임박 필터만 적용(정렬은 랭킹 순서 유지)
        base = base.where((m) {
          // minDaysLeft는 저장소 계산과 불일치 가능성이 있어, 랭커가 이미 임박도를 반영한 순서를 신뢰.
          // 그래도 완전 빈 목록 방지용으로는 메뉴 메타 값이 있으면 사용.
          return true; // 랭킹 순서 그대로 두고, 필요시 화면 임박 텍스트만 유지
        }).toList();
        break;

      case RecipeSortMode.frequency:
        // 부족 재료(필요-보유) 오름차순 + 랭킹 위치로 타이브레이크
        int missingByTitle(String title) {
          final r = byTitleAll[title];
          if (r == null) return 999;
          final miss = r.ingredientsTotal - r.ingredientsHave;
          return miss < 0 ? 0 : miss;
        }
        base.sort((a, b) {
          final am = missingByTitle(a.title);
          final bm = missingByTitle(b.title);
          if (am != bm) return am.compareTo(bm);
          return (_rankPos[a.title] ?? 1 << 30).compareTo(_rankPos[b.title] ?? 1 << 30);
        });
        break;

      case RecipeSortMode.favorite:
        // 즐겨찾기만 남기고 랭킹 순서 유지
        base = base.where((m) => m.favorite).toList();
        // 이미 랭킹 순서가 안정적이므로 추가 정렬 불필요
        break;
    }

    // MenuRec → Recipe 매핑 (정렬된 순서 유지)
    final ordered = <Recipe>[];
    for (final m in base) {
      final r = byTitleAll[m.title];
      if (r != null) ordered.add(r);
    }

    // 카테고리 필터
    List<Recipe> filtered = ordered;
    if (_selectedCategory != '전체') {
      final want = _selectedCategory;
      filtered = ordered.where((r) {
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
      filtered = filtered.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return filtered;
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

  // ======= UI (원본 그대로) =======
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
                          // 필요 시 API 필터까지 적용하려면:
                          // await _loadAll();
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

// ===== 정렬 칩 (홈과 동일 디자인) =====
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

// ===== 페이지네이션 버튼 위젯 =====
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
