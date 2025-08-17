import 'package:flutter/material.dart';
import '../../widgets/common/green_header.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/recipes/recipe_filter_chips.dart';
import '../../widgets/recipes/chip_scrollbar.dart';
import '../../widgets/recipes/recipe_card.dart';
import '../../data/mock_repository.dart';
import '../../models/recipe.dart';

/// 레시피 페이지 - 레시피 검색 및 필터링
/// 재료 보유 상태에 따른 레시피 추천 및 검색 기능 제공
class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  // ========== 상태 변수들 ==========

  /// 현재 선택된 필터
  String _selectedFilter = 'Can make now';

  /// 검색 텍스트 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  /// 검색 입력 포커스 노드
  final FocusNode _focusNode = FocusNode();

  /// 칩 스크롤 컨트롤러
  final ScrollController _chipController = ScrollController();

  /// 목 데이터 저장소
  final MockRepository _repository = MockRepository();

  /// 모든 레시피들
  List<Recipe> _allRecipes = [];

  /// 로딩 상태
  bool _isLoading = true;

  // ========== 계산된 속성들 ==========

  /// 필터별 레시피 개수
  Map<String, int> get _filterCounts {
    return {
      'Can make now': _allRecipes.where((r) => r.canMakeNow).length,
      'Almost ready': _allRecipes.where((r) => r.isAlmostReady).length,
      'Quick meals': _allRecipes.where((r) => r.isQuickMeal).length,
      'Vegetarian': _allRecipes.where((r) => r.isVegetarian).length,
    };
  }

  /// "만들 수 있는" 레시피 개수
  int get _canMakeCount => _filterCounts['Can make now'] ?? 0;

  /// "거의 완성" 레시피 개수
  int get _almostReadyCount => _filterCounts['Almost ready'] ?? 0;

  /// 필터링된 레시피들
  List<Recipe> get _filteredRecipes {
    List<Recipe> recipes = _allRecipes;

    // 필터 적용
    switch (_selectedFilter) {
      case 'Can make now':
        recipes = recipes.where((r) => r.canMakeNow).toList();
        break;
      case 'Almost ready':
        recipes = recipes.where((r) => r.isAlmostReady).toList();
        break;
      case 'Quick meals':
        recipes = recipes.where((r) => r.isQuickMeal).toList();
        break;
      case 'Vegetarian':
        recipes = recipes.where((r) => r.isVegetarian).toList();
        break;
    }

    // 검색 필터 적용
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      recipes = recipes.where((recipe) {
        return recipe.title.toLowerCase().contains(query) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return recipes;
  }

  // ========== 라이프사이클 메서드들 ==========

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _setupListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _chipController.dispose();
    super.dispose();
  }

  // ========== 초기 설정 ==========

  /// 리스너들 설정
  void _setupListeners() {
    _searchController.addListener(_onSearchChanged);
    _chipController.addListener(() => setState(() {}));

    // 첫 프레임 후 상태 계산
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // ========== 데이터 로딩 ==========

  /// 레시피들 로딩
  Future<void> _loadRecipes() async {
    try {
      final recipes = await _repository.getRecipes();
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('레시피를 불러오는데 실패했습니다.');
      }
    }
  }

  // ========== 빌드 메서드 ==========

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // 상단 헤더
              GreenHeader.recipes(
                readyCount: _canMakeCount,
                almostCount: _almostReadyCount,
              ),

              // 메인 콘텐츠
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // 검색바 (필터 버튼 포함)
                      CustomSearchBar.recipes(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onFilterPressed: _onFilterPressed,
                        focusNode: _focusNode,
                      ),

                      const SizedBox(height: 16),

                      // 필터 칩들
                      RecipeFilterChips(
                        selectedFilter: _selectedFilter,
                        filterCounts: _filterCounts,
                        onFilterChanged: _onFilterChanged,
                        scrollController: _chipController,
                      ),

                      const SizedBox(height: 8),

                      // 칩 스크롤바
                      ChipScrollbar(
                        scrollController: _chipController,
                        trackWidth: MediaQuery.of(context).size.width - 48,
                      ),

                      const SizedBox(height: 12),

                      // 레시피 리스트
                      Expanded(child: _buildRecipesList()),
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

  /// 레시피 리스트 빌드
  Widget _buildRecipesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredRecipes.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedSwitcher(
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
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: ScrollConfiguration(
        key: ValueKey(_selectedFilter),
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filteredRecipes.length,
          itemBuilder: (context, index) {
            final recipe = _filteredRecipes[index];
            return RecipeCard(
              recipe: recipe,
              onTap: () => _onRecipeTapped(recipe),
            );
          },
        ),
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (_searchController.text.isNotEmpty) {
      message = '검색 결과가 없습니다';
      subtitle = '다른 키워드로 검색해보세요';
      icon = Icons.search_off;
    } else {
      switch (_selectedFilter) {
        case 'Can make now':
          message = '지금 만들 수 있는 레시피가 없습니다';
          subtitle = '재료를 더 준비하거나 다른 필터를 선택해보세요';
          icon = Icons.no_meals;
          break;
        case 'Almost ready':
          message = '거의 완성 가능한 레시피가 없습니다';
          subtitle = '재료를 조금 더 준비하면 만들 수 있어요';
          icon = Icons.restaurant;
          break;
        case 'Quick meals':
          message = '빠른 요리 레시피가 없습니다';
          subtitle = '30분 이하로 만들 수 있는 요리를 찾아보세요';
          icon = Icons.timer;
          break;
        case 'Vegetarian':
          message = '채식 레시피가 없습니다';
          subtitle = '채식 요리 레시피를 추가해보세요';
          icon = Icons.eco;
          break;
        default:
          message = '레시피가 없습니다';
          subtitle = '새로운 레시피를 추가해보세요';
          icon = Icons.book;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ========== 이벤트 핸들러들 ==========

  /// 검색 텍스트 변경 처리
  void _onSearchChanged([String? value]) {
    setState(() {
      // 검색 결과 업데이트
    });
  }

  /// 필터 변경 처리
  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedFilter = newFilter;
    });
  }

  /// 필터 버튼 처리 (검색바 우측)
  void _onFilterPressed() {
    // TODO: 고급 필터 다이얼로그 또는 설정 페이지
    _showInfoSnackBar('고급 필터 기능은 준비 중입니다');
  }

  /// 레시피 탭 처리
  void _onRecipeTapped(Recipe recipe) {
    // TODO: 레시피 상세보기 페이지 이동
    _showInfoSnackBar('${recipe.title} 상세보기');
  }

  // ========== 스낵바 헬퍼들 ==========

  /// 오류 스낵바
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 정보 스낵바
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
