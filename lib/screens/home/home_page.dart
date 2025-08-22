// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';

// ==== 모델/헬퍼 ====
import '../../models/recipe.dart';
import '../../models/unified_recipe.dart';
import '../../models/menu_rec.dart';
import '../../models/fridge_item.dart';
import '../../services/recipe_sort_helper.dart';

// ==== 저장소/API ====
import '../../data/recipe_repository.dart';
import '../../data/remote/recipe_api.dart';
import '../../data/sample_data.dart';
import '../../data/mock_repository.dart'; // Add Item 등 로컬 목 동작에 사용

// ==== UI 위젯들 ====
import '../../widgets/home/expiry_indicator_bar.dart';
import '../../widgets/home/dynamic_header.dart';
import '../../widgets/home/fridge_timeline.dart';
import '../../widgets/home/menu_recommendations.dart';
import '../../widgets/common/add_item_dialog.dart';

// ==== 화면 이동 ====
import '../../screens/recipes/recipe_detail_page.dart';

// ==== 공용 타입(enum) ====
import 'home_types.dart';
export 'home_types.dart'; // 기존 import 경로를 유지하는 위젯들을 위한 재노출

/// 홈 메인 대시보드
class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, this.userName = '공육공육공'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ===== 상태 =====
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final RecipeRepository _recipeRepo; // API 기반 메뉴 소스
  final MockRepository _mockRepo = MockRepository(); // Add Item 등 목 동작

  SortMode _sortMode = SortMode.expiry;
  TimeFilter _timeFilter = TimeFilter.month;

  /// 화면에 표시되는 메뉴(이미 정렬/필터 적용된 최종 결과)
  List<MenuRec> _menus = [];
  bool _loadingMenus = true;

  /// 전체 모수(정렬 전 원본) + Recipe 인덱스(타이틀 매핑)
  List<MenuRec> _allMenus = [];
  Map<String, Recipe> _recipeByTitle = {};

  // 냉장고/타임라인은 샘플 데이터 사용(기존 동작 유지)
  List<FridgeItem> get _allFridgeItems => SampleData.timelineItems;

  int get _maxDaysForFilter {
    switch (_timeFilter) {
      case TimeFilter.week:
        return 7; // 1주
      case TimeFilter.month:
        return 28; // 1개월(4주)
      case TimeFilter.third:
        return 90; // 3개월
    }
  }

  List<FridgeItem> get _filteredFridgeItems =>
      SampleData.getFridgeItemsByTimeFilter(_maxDaysForFilter);

  // ===== 라이프사이클 =====
  @override
  void initState() {
    super.initState();

    // -- API 키 설정: dart-define 우선, 없으면 테스트용 하드코딩 --
    const defineKey = String.fromEnvironment('FOOD_API_KEY');
    const hardKey = 'b98006370cc24b529436'; // ⚠️ 실서비스에선 dart-define 사용 권장

    _recipeRepo = RecipeRepository(
      api: RecipeApi(
        base: 'https://openapi.foodsafetykorea.go.kr',
        keyId: (defineKey.isNotEmpty ? defineKey : hardKey),
        serviceId: 'COOKRCP01',
      ),
    );

    _loadHomeData(); // 최초 로드 (전체 모수 확보 → 공용 헬퍼 정렬)
  }

  @override
  void dispose() {
    _clearAllSnackBars();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== 데이터 로드(전체 모수 확보) =====
  /// 레시피 페이지와 동일한 "충분한 모수"를 홈에서도 확보하고,
  /// 공용 정렬 규칙(RecipeSortHelper)으로 화면용 목록을 만든다.
  Future<void> _loadHomeData() async {
    try {
      setState(() => _loadingMenus = true);

      final keyword = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      // ---- 1) 메뉴 전체 수집 (간단 페이지 루프) ----
      //  - Repository에 통합 fetch가 없다면 searchMenus를 페이징 호출
      //  - API 제한/속도에 맞춰 pageSize, maxPages는 필요 시 조정
      const int pageSize = 100;
      const int maxPages = 50;

      final List<MenuRec> gathered = [];
      for (int page = 1; page <= maxPages; page++) {
        final chunk = await _recipeRepo.searchMenus(
          keyword: keyword, // RCP_NM
          dishType: null, // 전체
          include: null,
          page: page,
          pageSize: pageSize,
        );
        if (chunk.isEmpty) break;
        gathered.addAll(chunk);

        // 안전장치: 너무 많을 때 중단(필요 시 상한 조정)
        if (gathered.length >= 20000) break;
      }

      // ---- 2) Recipe 인덱스 구성 (타이틀 매핑) ----
      //  - 홈에서도 레시피 페이지의 ingredientsHave/Total 기준을 사용하도록,
      //    보유 메뉴(MenuRec)를 Recipe로 변환하여 인덱스 구축
      //  - title 정규화 키로 매핑
      final List<Recipe> recipeList = gathered
          .map((m) => m.toRecipe())
          .toList();
      final recipeIndex = RecipeSortHelper.buildRecipeIndex(recipeList);

      // ---- 3) 공용 정렬 규칙으로 화면용 목록 산출 ----
      final visible = RecipeSortHelper.sortAndFilterMenus(
        menus: gathered,
        recipeByTitle: recipeIndex,
        mode: _sortMode,
        expiryThresholdDays: 7,
      );

      if (!mounted) return;
      setState(() {
        _allMenus = gathered;
        _recipeByTitle = recipeIndex;
        _menus = visible;
        _loadingMenus = false;
      });
    } catch (e) {
      // 실패 시 샘플 폴백 (이전 동작 유지)
      if (!mounted) return;
      _showSnack('레시피 API 호출 실패. 샘플 데이터로 표시합니다.', Colors.orange);

      // 샘플로도 동일 정렬 규칙 적용
      final sample = SampleData.menuRecommendations;
      final sampleRecipes = sample.map((m) => m.toRecipe()).toList();
      final sampleIndex = RecipeSortHelper.buildRecipeIndex(sampleRecipes);
      final visible = RecipeSortHelper.sortAndFilterMenus(
        menus: sample,
        recipeByTitle: sampleIndex,
        mode: _sortMode,
        expiryThresholdDays: 7,
      );

      setState(() {
        _allMenus = sample;
        _recipeByTitle = sampleIndex;
        _menus = visible;
        _loadingMenus = false;
      });
    }
  }

  /// 정렬 모드 변경 시, 공용 규칙으로 다시 계산
  void _onSortModeChanged(SortMode mode) {
    setState(() => _sortMode = mode);

    final visible = RecipeSortHelper.sortAndFilterMenus(
      menus: _allMenus,
      recipeByTitle: _recipeByTitle,
      mode: _sortMode,
      expiryThresholdDays: 7,
    );

    setState(() {
      _menus = visible;
    });
  }

  // ===== 메뉴 카드 탭 처리 =====
  /// 메뉴 추천 카드를 클릭했을 때의 처리
  /// 1. 클릭 카운트 증가 (사용 빈도 반영)
  /// 2. Recipe 객체로 변환 후 상세 페이지로 이동
  void _onMenuTapped(MenuRec menu) {
    try {
      // 1. 클릭 횟수/최근성 로컬 반영
      setState(() {
        final idx = _menus.indexOf(menu);
        if (idx >= 0) {
          _menus[idx] = _menus[idx].incrementClick();
        }
      });

      // 2. MenuRec → Recipe 변환
      final recipe = menu.toRecipe();

      // 3. 레시피 상세 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
      );

      // 4. 성공 피드백 (선택사항)
      _showSnack('${menu.title} 레시피 보기', const Color.fromARGB(255, 30, 0, 255));
    } catch (e) {
      _showSnack('레시피 정보를 불러올 수 없습니다.', Colors.red);
      // ignore: avoid_print
      print('MenuRec to Recipe 변환 실패: $e');
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final name = widget.userName;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 상단 동적 헤더
                  DynamicHeader(
                    fridgeItems: _allFridgeItems,
                    menuRecommendations: _menus,
                    todoCount: 3, // TODO: 실제 TODO 개수로 교체
                  ),

                  const SizedBox(height: 16),

                  // 유통기한 인디케이터
                  ExpiryIndicatorBar(fridgeItems: _allFridgeItems),

                  const SizedBox(height: 16),

                  // 메인 콘텐츠
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // 냉장고 타임라인
                        FridgeTimeline(
                          userName: name,
                          fridgeItems: _filteredFridgeItems,
                          currentFilter: _timeFilter,
                          onFilterChanged: (f) =>
                              setState(() => _timeFilter = f),
                        ),

                        const SizedBox(height: 24),

                        // 메뉴 추천
                        _loadingMenus
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : MenuRecommendations(
                                // ✅ 이미 공용 규칙으로 정렬/필터를 끝낸 결과를 그대로 넘김
                                menuRecommendations: _menus,
                                currentSortMode: _sortMode,
                                onSortModeChanged: _onSortModeChanged,
                                onMenuTapped: _onMenuTapped,
                                onFavoriteToggled: (menu) {
                                  setState(() {
                                    final idx = _menus.indexOf(menu);
                                    if (idx >= 0) {
                                      _menus[idx] = _menus[idx].copyWith(
                                        favorite: !menu.favorite,
                                      );
                                    }
                                  });
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Quick Action FAB
      floatingActionButton: FloatingActionButton(
        onPressed: _onQuickActionPressed,
        backgroundColor: const Color.fromARGB(255, 30, 0, 255),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ===== Quick Actions =====
  void _onQuickActionPressed() => _showQuickActionDialog();

  void _showQuickActionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Add Item
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color.fromARGB(255, 30, 0, 255),
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Add Item'),
              subtitle: const Text('냉장고에 새 아이템 추가'),
              onTap: () async {
                Navigator.pop(context);
                final newItem = await AddItemDialog.show(context);
                if (newItem != null) {
                  try {
                    await _mockRepo.addFridgeItem(newItem);
                    _showSnack(
                      '${newItem.name}이(가) 추가되었습니다',
                      const Color.fromARGB(255, 30, 0, 255),
                    );
                  } catch (_) {
                    _showSnack('아이템 추가에 실패했습니다', Colors.red);
                  }
                }
              },
            ),

            // Scan Receipt
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color.fromARGB(255, 30, 0, 255),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Scan Receipt'),
              subtitle: const Text('영수증 스캔으로 한 번에 추가'),
              onTap: () {
                Navigator.pop(context);
                _showSnack('영수증 스캔 기능', const Color.fromARGB(255, 30, 0, 255));
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===== 스낵바 =====
  void _clearAllSnackBars() {
    if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
  }

  void _showSnack(String msg, Color c, {int ms = 1500}) {
    _clearAllSnackBars();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: c,
        duration: Duration(milliseconds: ms),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
