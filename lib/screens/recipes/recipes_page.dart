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
  static const int _expiryThresholdDays = 7; // 유통기한 임박 기준
  static const int _pageSize = 10;

  // "필수 재료 개수 < N" 글로벌 필터(카테고리/리스트 공통 적용)
  static const int _maxRequiredIngredients = 15; // 미만 조건
  // 페이지네이션 상태
  int _currentPage = 1;

  // 검색 디바운스
  Timer? _debounce;

  // ===== 파생 =====
  // 카테고리 카운트: ['전체','밥','국&찌개','반찬','후식'] 기준
  Map<String, int> get _categoryCounts {
    final subset = _allRecipes
        .where(
          (r) =>
              r.ingredientsTotal >= 0 &&
              r.ingredientsTotal < _maxRequiredIngredients,
        )
        .toList();

    final base = <String, int>{
      '전체': subset.length,
      '밥': 0,
      '국&찌개': 0,
      '반찬': 0,
      '후식': 0,
    };

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
        base: 'https://openapi.foodsafetykorea.go.kr', // TODO: 환경변수로 추출 가능
        keyId: 'b98006370cc24b529436', // ★ 발급키 삽입
        serviceId: 'COOKRCP01',
      ),
    );
    _loadAll(); // 최초 전체 로드
  }

  @override
  void dispose() {
    _clearAllSnackBars();
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // =========================
  // 데이터 로드
  // =========================
  Future<void> _loadAll() async {
    try {
      setState(() {
        _isLoading = true;
        _currentPage = 1; // 검색/필터 변경 시 첫 페이지로
      });

      final keyword = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      final dish = _mapCategoryToRcpPat2(_selectedCategory); // 카테고리 → API 값

      // 전체 로드: fetchAll 사용 (왕복 줄이기 위해 pageSize 크게)
      final recipes = await _repository.fetchAllRecipes(
        keyword: keyword,
        dishType: dish,
        include: null,
        pageSize: 100,
      );
      final menus = await _repository.fetchAllMenus(
        keyword: keyword,
        dishType: dish,
        include: null,
        pageSize: 100,
      );

      if (!mounted) return;
      setState(() {
        _allRecipes = recipes; // 원본 유지 (필요재료<20 필터는 화면 단계에서 적용)
        _allMenus = menus;
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

    // 0) "필요재료개수 < 20" 필터를 화면 단계에서 선적용
    final byTitleAll = {for (final r in _allRecipes) r.title: r};
    final allowedTitles = _allRecipes
        .where(
          (r) =>
              r.ingredientsTotal >= 0 &&
              r.ingredientsTotal < _maxRequiredIngredients,
        )
        .map((r) => r.title)
        .toSet();

    // 1) 정렬 기준: MenuRec 정렬 → Recipe 매핑
    final byTitle = byTitleAll;
    List<MenuRec> menus = _allMenus
        .where((m) => allowedTitles.contains(m.title))
        .toList();

    // 헬퍼: 부족 개수(= 필요−보유) — 모델 값으로 계산(안전)
    int missingByRecipe(MenuRec m) {
      final r = byTitle[m.title];
      if (r == null) return 999;
      final miss = r.ingredientsTotal - r.ingredientsHave;
      return miss < 0 ? 0 : miss;
    }

    switch (_sortMode) {
      case RecipeSortMode.expiry:
        // ✅ "유통기한 임박 재료를 포함한 메뉴만" 표시
        menus = menus
            .where((m) => m.minDaysLeft < _expiryThresholdDays)
            .toList();

        // 남은 일수 오름차순 → 즐겨찾기 내림차순 → 제목
        menus.sort((a, b) {
          final dl = a.minDaysLeft.compareTo(b.minDaysLeft);
          if (dl != 0) return dl;

          if (a.favorite != b.favorite) {
            return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
          }
          return a.title.compareTo(b.title);
        });
        break;

      case RecipeSortMode.frequency:
        // ✅ 보유재료 0개인 메뉴 제외
        menus = menus
            .where((m) => (byTitle[m.title]?.ingredientsHave ?? 0) > 0)
            .toList();

        // ✅ (필요−보유) 오름차순, 동률이면 임박/남은 일수/즐겨찾기/제목
        menus.sort((a, b) {
          final am = missingByRecipe(a);
          final bm = missingByRecipe(b);
          if (am != bm) return am.compareTo(bm);

          // tie-breaker 1: 임박 우선
          final aUrgent = a.minDaysLeft < _expiryThresholdDays ? 0 : 1;
          final bUrgent = b.minDaysLeft < _expiryThresholdDays ? 0 : 1;
          if (aUrgent != bUrgent) return aUrgent - bUrgent;

          // tie-breaker 2: 남은 일수 오름차순
          final dl = a.minDaysLeft.compareTo(b.minDaysLeft);
          if (dl != 0) return dl;

          // tie-breaker 3: 즐겨찾기 내림차순
          if (a.favorite != b.favorite) {
            return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
          }

          // tie-breaker 4: 제목
          return a.title.compareTo(b.title);
        });
        break;

      case RecipeSortMode.favorite:
        // ✅ 즐겨찾기된 메뉴만 표시
        menus = menus.where((m) => m.favorite).toList();
        menus.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    // 2) MenuRec → Recipe 매핑 (정렬된 순서 유지)
    List<Recipe> ordered = [];
    for (final m in menus) {
      final r = byTitle[m.title];
      if (r != null) ordered.add(r);
    }

    ordered = ordered
        .where((r) => (r.ingredientsTotal) < _maxRequiredIngredients)
        .toList();

    // 3) 카테고리 필터(로컬)
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

    // 4) 검색(제목/태그)
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

  // ======= UI =======
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
                          // 네트워크 재호출 없이 UX용 짧은 로딩만 표시
                          setState(() {
                            _selectedCategory = c;
                            _isLoading = true;
                            _currentPage = 1;
                          });
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );
                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                          // 카테고리 변경 시 API 필터까지 적용하려면:
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

  // 하단 페이지네이션(이전/다음 + 현재/총 페이지)
  Widget _buildPaginator() {
    final total = _totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PgBtn(
            icon: Icons.chevron_left,
            onTap: _currentPage > 1
                ? () => setState(() => _currentPage -= 1)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            '$_currentPage / $total',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          _PgBtn(
            icon: Icons.chevron_right,
            onTap: _currentPage < total
                ? () => setState(() => _currentPage += 1)
                : null,
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
    // API 예: '반찬', '국', '후식', '밥', '면' …
    switch (ui) {
      case '전체':
        return null;
      case '밥':
        return '밥';
      case '국&찌개':
        return '국&찌개'; // API에 따라 '국'/'찌개' 분리 가능성 있어 유지
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color.fromARGB(255, 30, 0, 255)
                      : const Color.fromARGB(255, 255, 255, 255),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSel
                              ? const Color.fromARGB(255, 30, 0, 255)
                              : Colors.black54,
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
          color: current == m
              ? const Color.fromARGB(255, 30, 0, 255)
              : const Color.fromARGB(255, 255, 255, 255),
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
