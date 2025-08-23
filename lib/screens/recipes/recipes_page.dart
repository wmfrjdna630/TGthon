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

  // ‘전체’ 탭 = 홈페이지와 동일 파이프라인 데이터
  List<MenuRec> _homeMenusAll = [];
  List<MenuRec> _homeRankedMenus = [];
  Map<String, Recipe> _homeRecipeByTitle = {};

  // 카테고리 탭용 데이터
  List<Recipe> _allRecipes = [];
  List<MenuRec> _rankedMenusForCategories = [];
  Map<String, int> _rankPosForCategories = {};

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

  // 냉장고 실시간
  final FridgeRemoteRepository _fridgeRepo = FridgeRemoteRepository();
  List<FridgeItem> _fridgeItems = [];
  StreamSubscription<List<FridgeItem>>? _fridgeSub;

  // ===== 파생 =====
  Map<String, int> get _categoryCounts {
    if (_selectedCategory == '전체') {
      final byTitle = _homeRecipeByTitle;
      int total = 0, rice = 0, soup = 0, side = 0, dessert = 0;
      for (final m in _homeRankedMenus) {
        final r = byTitle[m.title];
        if (r == null) continue;
        total++;
        final tags = r.tags.map((t) => t.trim().toLowerCase()).toSet();
        if (tags.contains('밥')) rice++;
        if (tags.contains('국&찌개')) soup++;
        if (tags.contains('반찬')) side++;
        if (tags.contains('후식')) dessert++;
      }
      return {
        '전체': total,
        '밥': rice,
        '국&찌개': soup,
        '반찬': side,
        '후식': dessert,
      };
    }

    // 카테고리 탭: 총 재료 < 15 필터 적용
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

  int get _canMakeCount => _selectedCategory == '전체'
      ? _homeRecipeByTitle.values.where((r) => r.canMakeNow).length
      : _allRecipes
          .where((r) => r.ingredientsTotal < _maxRequiredIngredients)
          .where((r) => r.canMakeNow)
          .length;

  int get _almostReadyCount => _selectedCategory == '전체'
      ? _homeRecipeByTitle.values.where((r) => r.isAlmostReady).length
      : _allRecipes
          .where((r) => r.ingredientsTotal < _maxRequiredIngredients)
          .where((r) => r.isAlmostReady)
          .length;

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
        keyId: 'sample', // 쿼터 회피용. 배포 시 dart-define로 교체 가능.
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
  // 냉장고 초기화 + 실시간 반영 + 로드
  // =========================
  Future<void> _initFridgeAndLoad() async {
    try {
      final first = await _fridgeRepo.getFridgeItems();
      _fridgeItems = first;
    } catch (_) {/* ignore */}

    _fridgeSub?.cancel();
    _fridgeSub = _fridgeRepo.watchFridgeItems().listen((items) async {
      _fridgeItems = items;
      _recomputeHaveCountsEverywhere(); // 냉장고 변경 시: 보유 수 재계산
      _rerankWithCurrentData();         // → 재랭킹
      if (mounted) setState(() {});     // 숫자/순위 반영
    });

    await _loadAll();
  }

  // =========================
  // 문자열 정규화 & 매칭 유틸 (소금/후추 등 별칭 포함)
  // =========================
  static final Map<String, List<String>> _alias = {
    '소금': ['천일염', '정제염', '꽃소금', '굵은소금', '맛소금'],
    '후추': ['흑후추', '검은후추', '백후추', '그라인드후추', '통후추', '후춧가루'],
    '간장': ['진간장', '국간장', '양조간장'],
    '고추장': ['된고추장', '고추장양념'],
    '대파': ['파', '쪽파'],
    '마늘': ['다진마늘', '다진 마늘'],
    '설탕': ['백설탕', '갈색설탕', '흑설탕', '설탕가루'],
    '식용유': ['식물성기름', '카놀라유', '콩기름', '올리브유'],
    '참기름': ['들기름'],
    '버터': ['무염버터', '가염버터'],
    '우유': ['저지방우유', '전지분유', '분유'],
    '양파': ['적양파', '양파채'],
  };

  String _norm(String s) {
    final lower = s.toLowerCase();
    final removed = lower.replaceAll(
      RegExp(
      r'''[\s\(\)\[\]\{\}\.,/·\-~!@#\$%\^&\*\+=:;'"<>？?]'''
    ),
      '',
    );
    return removed;
  }

  Set<String> _expandFridgeTokens() {
    final set = <String>{};
    for (final f in _fridgeItems) {
      final base = f.name.trim();
      if (base.isEmpty) continue;
      final n = _norm(base);
      if (n.isEmpty) continue;
      set.add(n);

      // 별칭 양방향 확장
      if (_alias.containsKey(base)) {
        for (final a in _alias[base]!) {
          set.add(_norm(a));
        }
      }
      _alias.forEach((k, vals) {
        for (final v in vals) {
          if (_norm(v) == n) set.add(_norm(k));
        }
      });
    }
    return set;
  }

  String _recipeTextForMatch(Recipe r) {
    // 제목 + 태그 + description(여기에 RCP_PARTS_DTLS 들어오는 경우 多)
    final title = r.title;
    final tags = (r.tags.isEmpty ? '' : ' ' + r.tags.join(' '));
    final desc = r.description ?? '';
    return '$title$tags $desc';
  }

  int _haveCountFromFridge(Recipe r) {
    final fridgeTokens = _expandFridgeTokens();
    if (fridgeTokens.isEmpty) return 0;

    final text = _norm(_recipeTextForMatch(r));
    if (text.isEmpty) return 0;

    int cnt = 0;
    final seen = <String>{};
    for (final t in fridgeTokens) {
      if (t.isEmpty || seen.contains(t)) continue;
      if (text.contains(t)) {
        cnt++;
        seen.add(t);
      }
    }
    return cnt;
  }

  void _recomputeHaveCountsEverywhere() {
    // ‘전체’ 탭 데이터
    if (_homeRecipeByTitle.isNotEmpty) {
      final updated = <String, Recipe>{};
      _homeRecipeByTitle.forEach((title, r) {
        final have = _haveCountFromFridge(r);
        updated[title] = r.copyWith(
          ingredientsHave:
              (r.ingredientsTotal > 0) ? have.clamp(0, r.ingredientsTotal) : have,
        );
      });
      _homeRecipeByTitle = updated;
    }

    // 카테고리 탭 데이터
    if (_allRecipes.isNotEmpty) {
      _allRecipes = _allRecipes.map((r) {
        final have = _haveCountFromFridge(r);
        return r.copyWith(
          ingredientsHave:
              (r.ingredientsTotal > 0) ? have.clamp(0, r.ingredientsTotal) : have,
        );
      }).toList();
    }
  }

  void _rerankWithCurrentData() {
    // ‘전체’ 탭 재랭킹
    if (_homeMenusAll.isNotEmpty && _homeRecipeByTitle.isNotEmpty) {
      final rankerHome = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );
      var ranked = rankerHome.sortByPriority(
        menus: _homeMenusAll,
        recipeByTitle: _homeRecipeByTitle,
      );
      ranked = _applyPostPolicies(ranked, _homeRecipeByTitle);
      _homeRankedMenus = ranked;
    }

    // 카테고리 탭 재랭킹
    if (_rankedMenusForCategories.isNotEmpty && _allRecipes.isNotEmpty) {
      final byTitleCat = {for (final r in _allRecipes) r.title: r};
      final rankerCat = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );
      var rankedCat = rankerCat.sortByPriority(
        menus: _rankedMenusForCategories,
        recipeByTitle: byTitleCat,
      );
      final posCat = <String, int>{};
      for (int i = 0; i < rankedCat.length; i++) {
        posCat[rankedCat[i].title] = i;
      }
      _rankPosForCategories = posCat;
      _rankedMenusForCategories = rankedCat;
    }
  }

  List<MenuRec> _applyPostPolicies(List<MenuRec> ranked, Map<String, Recipe> idx) {
    ranked = ranked.where((m) {
      final r = idx[m.title];
      if (r == null) return false;
      return r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients;
    }).toList();

    final withHave = <MenuRec>[];
    final withoutHave = <MenuRec>[];
    for (final m in ranked) {
      final have = idx[m.title]?.ingredientsHave ?? 0;
      (have > 0 ? withHave : withoutHave).add(m);
    }
    return [...withHave, ...withoutHave];
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

      // ---------- ‘전체’ 탭: 홈페이지와 동일 파이프라인 ----------
      final List<MenuRec> gathered = [];
      const int pageSize = 100;
      const int maxPages = 50;
      for (int page = 1; page <= maxPages; page++) {
        final chunk = await _repository.searchMenus(
          keyword: keyword,
          dishType: null,
          include: null,
          page: page,
          pageSize: pageSize,
        );
        if (chunk.isEmpty) break;
        gathered.addAll(chunk);
        if (gathered.length >= 20000) break; // 안전 상한
      }
      _homeMenusAll = gathered;

      // ‘전체’ 탭의 have 정밀 계산을 위해 디테일도 일부 확보 (임박 냉장고 기반으로 폭 좁혀 요청)
      final includeParamForDetail = _buildIncludeFromFridge(limit: 8);
      final detailRecipes = await _repository.fetchAllRecipes(
        keyword: keyword,
        dishType: null,
        include: includeParamForDetail,
        pageSize: 100,
      );
      final detailsByTitle = {for (final r in detailRecipes) r.title: r};

      // toRecipe → details로 보강 → 냉장고 기반 have 재산출
      final recipeIndexHome = <String, Recipe>{};
      for (final m in gathered) {
        final base = m.toRecipe();
        final d = detailsByTitle[base.title];
        final enriched = (d == null)
            ? base
            : base.copyWith(
                description: d.description ?? base.description,
                // 태그 합치기(중복 제거)
                tags: {
                  ...base.tags.map((t) => t.trim()),
                  ...d.tags.map((t) => t.trim()),
                }.toList(),
                // 총 재료 수는 detail 쪽이 더 정확한 경우 우선
                ingredientsTotal: (d.ingredientsTotal > 0)
                    ? d.ingredientsTotal
                    : base.ingredientsTotal,
              );
        final have = _haveCountFromFridge(enriched);
        recipeIndexHome[enriched.title] = enriched.copyWith(
          ingredientsHave: (enriched.ingredientsTotal > 0)
              ? have.clamp(0, enriched.ingredientsTotal)
              : have,
        );
      }
      final rankerHome = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );
      var rankedHome = rankerHome.sortByPriority(
        menus: gathered,
        recipeByTitle: recipeIndexHome,
      );
      rankedHome = _applyPostPolicies(rankedHome, recipeIndexHome);

      // ---------- 카테고리 탭: 기존 파이프라인 ----------
      final includeParam = _buildIncludeFromFridge(limit: 8); // 후보만 좁힘
      final recipesAll = await _repository.fetchAllRecipes(
        keyword: keyword,
        dishType: dish,
        include: includeParam,
        pageSize: 100,
      );
      final menusAll = await _repository.fetchAllMenus(
        keyword: keyword,
        dishType: dish,
        include: includeParam,
        pageSize: 100,
      );

      // 냉장고 기반 have 재산출
      final rebasedRecipes = <Recipe>[];
      for (final r in recipesAll) {
        final have = _haveCountFromFridge(r);
        rebasedRecipes.add(
          r.copyWith(
            ingredientsHave:
                (r.ingredientsTotal > 0) ? have.clamp(0, r.ingredientsTotal) : have,
          ),
        );
      }

      // 카테고리 탭 랭킹
      final byTitleCat = {for (final r in rebasedRecipes) r.title: r};
      final rankerCat = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );
      final rankedCat = rankerCat.sortByPriority(
        menus: menusAll,
        recipeByTitle: byTitleCat,
      );
      final posCat = <String, int>{};
      for (int i = 0; i < rankedCat.length; i++) {
        posCat[rankedCat[i].title] = i;
      }

      if (!mounted) return;
      setState(() {
        _homeRecipeByTitle = recipeIndexHome;
        _homeRankedMenus = rankedHome;

        _allRecipes = rebasedRecipes;
        _rankedMenusForCategories = rankedCat;
        _rankPosForCategories = posCat;

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
  // =========================
  List<Recipe> get _displayListUnpaged {
    if (_isLoading) return const [];

    // ▶︎ ‘전체’ 탭: 홈페이지와 완전 동일 순서/구성(보유 수 재계산 반영됨)
    if (_selectedCategory == '전체') {
      final base = _homeRankedMenus;
      final List<Recipe> out = [];
      for (final m in base) {
        final r = _homeRecipeByTitle[m.title];
        if (r != null) out.add(r);
      }
      return out;
    }

    // ▶︎ 카테고리 탭: 기존 정책(총 재료 < 15, 모드별 보조정렬/필터)
    final byTitleAll = {for (final r in _allRecipes) r.title: r};
    final allowedTitles = _allRecipes
        .where((r) => r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients)
        .map((r) => r.title)
        .toSet();

    List<MenuRec> base = _rankedMenusForCategories
        .where((m) => allowedTitles.contains(m.title))
        .toList();

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
          return (_rankPosForCategories[a.title] ?? 1 << 30)
              .compareTo(_rankPosForCategories[b.title] ?? 1 << 30);
        });
        break;

      case RecipeSortMode.favorite:
        base = base.where((m) => m.favorite).toList();
        break;
    }

    // MenuRec → Recipe
    List<Recipe> ordered = [];
    for (final m in base) {
      final r = byTitleAll[m.title];
      if (r != null) ordered.add(r);
    }

    // 카테고리 필터
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
                          // 필요 시 API 재조회: await _loadAll();
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
    if (!mounted) return;
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
      await _loadAll(); // 검색어 반영하여 전체 재조회
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
