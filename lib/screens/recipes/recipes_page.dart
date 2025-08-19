// lib/screens/recipes/recipes_page.dart
import 'package:flutter/material.dart';
import '../../widgets/common/blue_header.dart';
import '../../widgets/recipes/recipe_card.dart';
import '../../data/mock_repository.dart';
import '../../data/sample_data.dart';
import '../../models/recipe.dart';
import '../../models/menu_rec.dart';
import '../../widgets/common/compact_search_bar.dart';

/// 정렬 모드 (홈과 동일한 의미)
enum RecipeSortMode { expiry, frequency, favorite }

/// 레시피 페이지 - 단일 더미(한글) 사용
/// 상단 카테고리: 전체 / 한식 / 중식 / 양식 / 일식 / 간식
/// 정렬 탭: 유통기한순 / 빈도순 / 즐겨찾는순
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
  final MockRepository _repository = MockRepository();

  List<Recipe> _allRecipes = [];
  List<MenuRec> _allMenus = []; // 정렬에 필요한 홈 속성 참조
  bool _isLoading = true;

  // ===== 파생 =====
  Map<String, int> get _categoryCounts {
    final base = <String, int>{
      '전체': _allRecipes.length,
      '한식': 0,
      '중식': 0,
      '양식': 0,
      '일식': 0,
      '간식': 0,
    };
    for (final r in _allRecipes) {
      for (final c in ['한식', '중식', '양식', '일식', '간식']) {
        if (r.tags.contains(c)) base[c] = (base[c] ?? 0) + 1;
      }
    }
    return base;
  }

  int get _canMakeCount => _allRecipes.where((r) => r.canMakeNow).length;
  int get _almostReadyCount => _allRecipes.where((r) => r.isAlmostReady).length;

  // ===== 라이프사이클 =====
  @override
  void initState() {
    super.initState();
    _loadUnified();
  }

  @override
  void dispose() {
    _clearAllSnackBars();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUnified() async {
    try {
      final recipes = await _repository
          .getRecipes(); // SampleData.recipes (단일 소스 파생)
      final menus = await _repository
          .getMenuRecommendations(); // SampleData.menuRecommendations (단일 소스 파생)
      if (!mounted) return;
      setState(() {
        _allRecipes = recipes;
        _allMenus = menus;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('레시피를 불러오는데 실패했습니다.');
    }
  }

  // ===== 정렬/필터 후 리스트 =====
  List<Recipe> get _displayList {
    if (_isLoading) return const [];

    // 1) 정렬 기준: MenuRec 속성에 의존 (minDaysLeft, favorite 등)
    final byTitle = {for (final r in _allRecipes) r.title: r};
    List<MenuRec> menus = List<MenuRec>.from(_allMenus);

    switch (_sortMode) {
      case RecipeSortMode.expiry:
        menus.sort((a, b) => a.minDaysLeft.compareTo(b.minDaysLeft));
        break;
      case RecipeSortMode.frequency:
        // 홈과 동일 로직: 부족한 필수재료 < 3 인 메뉴만, 부족 개수 오름차순.
        final owned = SampleData.fridgeItems
            .map((e) => e.name.trim().toLowerCase())
            .toSet();
        int missing(MenuRec m) => _missingRequiredCount(m, owned);
        menus = menus.where((m) => missing(m) < 3).toList()
          ..sort((a, b) {
            final am = missing(a), bm = missing(b);
            if (am != bm) return am.compareTo(bm);
            final ex = a.minDaysLeft.compareTo(b.minDaysLeft);
            if (ex != 0) return ex;
            if (a.favorite != b.favorite) {
              return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
            }
            return a.title.compareTo(b.title);
          });
        break;
      case RecipeSortMode.favorite:
        menus.sort((a, b) {
          if (a.favorite == b.favorite) return a.title.compareTo(b.title);
          return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
        });
        break;
    }

    // 2) MenuRec 정렬 순서를 Recipe로 매핑
    List<Recipe> ordered = [];
    for (final m in menus) {
      final r = byTitle[m.title];
      if (r != null) ordered.add(r);
    }

    // 3) 카테고리 필터
    if (_selectedCategory != '전체') {
      ordered = ordered
          .where((r) => r.tags.contains(_selectedCategory))
          .toList();
    }

    // 4) 검색
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      ordered = ordered.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return ordered;
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
                        onChanged: (_) => setState(() {}),
                        focusNode: _focusNode,
                      ),
                      const SizedBox(height: 16),
                      _CategoryChips(
                        selected: _selectedCategory,
                        counts: _categoryCounts,
                        onChanged: (c) => setState(() => _selectedCategory = c),
                      ),
                      const SizedBox(height: 8),
                      _SortChips(
                        current: _sortMode,
                        onChanged: (m) => setState(() => _sortMode = m),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _buildList()),
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
    final list = _displayList;
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

  // ===== 홈의 빈도순 로직과 동일한 "부족 개수" 계산기 =====
  int _missingRequiredCount(MenuRec menu, Set<String> owned) {
    if (menu.hasAllRequired) return 0;
    final msg = (menu.needMessage).trim();
    if (msg.isEmpty) return 999;
    final parts = msg
        .toLowerCase()
        .replaceAll('!', ' ')
        .replaceAll('요.', ' ')
        .split(RegExp(r'[,\u00B7\u2022/·∙•]| 그리고 | 및 | 와 | 과 | 혹은 | 또는 '));
    final tokens = parts
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where((s) => s.runes.length >= 1 && s.runes.length <= 12)
        .toSet()
        .toList();
    return tokens.length;
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
    final items = ['전체', '한식', '중식', '양식', '일식', '간식'];
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
