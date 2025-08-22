// lib/screens/home/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

// ==== 모델/헬퍼 ====
import '../../models/recipe.dart';
// import '../../models/unified_recipe.dart'; // <- 사용하지 않아 제거
import '../../models/menu_rec.dart';
import '../../models/fridge_item.dart';
import '../../services/recipe_sort_helper.dart';

// ==== 저장소/API ====
import '../../data/recipe_repository.dart';
import '../../data/remote/recipe_api.dart';
import '../../data/remote/fridge_repository.dart';

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
export 'home_types.dart'; // 다른 위젯에서 기존 경로 기대 시 편의 제공

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

  // 냉장고: Firestore 연동
  final FridgeRemoteRepository _fridgeRepo = FridgeRemoteRepository();
  List<FridgeItem> _fridgeItems = [];
  bool _loadingFridge = false; // <-- 실제 UI에 표시하도록 사용

  // 추천/정렬 상태
  SortMode _sortMode = SortMode.expiry;
  TimeFilter _timeFilter = TimeFilter.month;

  /// 화면에 표시되는 메뉴(이미 정렬/필터 적용된 최종 결과)
  List<MenuRec> _menus = [];
  bool _loadingMenus = true;

  /// 전체 모수(정렬 전 원본) + Recipe 인덱스(타이틀 매핑)
  List<MenuRec> _allMenus = [];
  Map<String, Recipe> _recipeByTitle = {};

  // 냉장고(전체)
  List<FridgeItem> get _allFridgeItems => _fridgeItems;

  // 현재 필터 기준(주/월/3개월)
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

  // 냉장고(필터 적용)
  List<FridgeItem> get _filteredFridgeItems =>
      _fridgeItems.where((it) => it.daysLeft <= _maxDaysForFilter).toList();

  StreamSubscription<List<FridgeItem>>? _fridgeSub; // (선택) 실시간 반영 시 사용

  // ===== 라이프사이클 =====
  @override
  void initState() {
    super.initState();

    // -- API 키 설정: dart-define 우선, 없으면 테스트용 하드코딩 --
    const defineKey = String.fromEnvironment('FOOD_API_KEY');
    const hardKey = 'b98006370cc24b529436'; // ⚠️ 실제 서비스에선 dart-define 사용 권장

    _recipeRepo = RecipeRepository(
      api: RecipeApi(
        base: 'https://openapi.foodsafetykorea.go.kr',
        keyId: (defineKey.isNotEmpty ? defineKey : hardKey),
        serviceId: 'COOKRCP01',
      ),
    );

    _loadFridgeItems(); // ← 홈 진입 시 실제 냉장고 데이터 로드
    _loadHomeData();    // 메뉴/추천 로드
  }

  @override
  void dispose() {
    _fridgeSub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ==============================
  // 냉장고 로드/추가
  // ==============================
  Future<void> _loadFridgeItems() async {
    setState(() => _loadingFridge = true);
    try {
      final items = await _fridgeRepo.getFridgeItems();
      if (!mounted) return;
      setState(() {
        _fridgeItems = items;
        _loadingFridge = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFridge = false);
      _showSnack('냉장고 불러오기 실패: $e', Colors.red);
    }
  }

  Future<void> _onAddItem() async {
    final newItem = await AddItemDialog.show(context);
    if (newItem == null) return;
    try {
      await _fridgeRepo.addFridgeItem(newItem); // Firestore에 추가
      await _loadFridgeItems();                 // 다시 불러와 홈에 반영
      _showSnack('${newItem.name}이(가) 추가되었습니다',
          const Color.fromARGB(255, 30, 0, 255));
    } catch (e) {
      _showSnack('아이템 추가에 실패했습니다: $e', Colors.red);
    }
  }

  // ==============================
  // 메뉴 로딩/정렬
  // ==============================
  Future<void> _loadHomeData() async {
    try {
      setState(() => _loadingMenus = true);

      final keyword = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      // ---- 1) 메뉴 전체 수집 (간단 페이지 루프) ----
      const int pageSize = 100;
      const int maxPages = 50;

      final List<MenuRec> gathered = [];
      for (int page = 1; page <= maxPages; page++) {
        final chunk = await _recipeRepo.searchMenus(
          keyword: keyword, // RCP_NM
          dishType: null,   // 전체
          include: null,
          page: page,
          pageSize: pageSize,
        );
        if (chunk.isEmpty) break;
        gathered.addAll(chunk);
        if (gathered.length >= 20000) break; // 안전상한
      }

      // ---- 2) Recipe 인덱스 구성 (타이틀 매핑) ----
      final List<Recipe> recipeList =
          gathered.map((m) => m.toRecipe()).toList();
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
        _menus = visible.take(10).toList(); // 상위 10개만 노출
        _loadingMenus = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('레시피 API 호출 실패', Colors.red);
      setState(() {
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
      _menus = visible.take(10).toList(); // 탭 전환 시도 10개로 제한
    });
  }

  // ===== 메뉴 카드 탭 처리 =====
  void _onMenuTapped(MenuRec menu) {
    try {
      setState(() {
        final idx = _menus.indexOf(menu);
        if (idx >= 0) {
          _menus[idx] = _menus[idx].incrementClick();
        }
      });

      final recipe = menu.toRecipe();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
      );

      _showSnack('${menu.title} 레시피 보기',
          const Color.fromARGB(255, 30, 0, 255));
    } catch (e) {
      _showSnack('레시피 이동 중 오류: $e', Colors.red);
    }
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {
    final name = widget.userName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(
            tooltip: '재료 추가',
            onPressed: _onAddItem,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
        bottom: _loadingFridge
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Center(
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
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '냉장고 타임라인',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_loadingFridge)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  FridgeTimeline(
                                    userName: name,
                                    fridgeItems: _filteredFridgeItems,
                                    currentFilter: _timeFilter,
                                    onFilterChanged: (f) =>
                                        setState(() => _timeFilter = f),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 추천 메뉴
                          _loadingMenus
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : MenuRecommendations(
                                  // 이미 공용 규칙으로 정렬/필터를 끝낸 결과(상위 10개)를 그대로 넘김
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

                          const SizedBox(height: 8),

                          // 하단 퀵액션 (제네릭 명시로 타입 추론 오류 제거)
                          Align(
                            alignment: Alignment.centerRight,
                            child: PopupMenuButton<void>(
                              tooltip: 'Quick actions',
                              itemBuilder: (context) =>
                                  <PopupMenuEntry<void>>[
                                PopupMenuItem<void>(
                                  child: const ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Color.fromARGB(255, 30, 0, 255),
                                      child:
                                          Icon(Icons.add, color: Colors.white),
                                    ),
                                    title: Text('Add Item'),
                                    subtitle: Text('냉장고에 새 아이템 추가'),
                                  ),
                                  onTap: () async {
                                    // 메뉴가 닫힌 뒤 실행되도록 프레임 지연
                                    await Future.delayed(Duration.zero);
                                    await _onAddItem();
                                  },
                                ),
                                const PopupMenuDivider(height: 6),
                                PopupMenuItem<void>(
                                  child: const ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Color.fromARGB(255, 30, 0, 255),
                                      child: Icon(Icons.camera_alt,
                                          color: Colors.white),
                                    ),
                                    title: Text('Scan Receipt'),
                                    subtitle: Text('영수증 스캔으로 한 번에 추가'),
                                  ),
                                  onTap: () async {
                                    // TODO: 영수증 스캔 기능 연결
                                  },
                                ),
                              ],
                              child: const Chip(
                                avatar: Icon(Icons.flash_on, size: 18),
                                label: Text('Quick Actions'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadHomeData,
        label: const Text('추천 새로고침'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  // ==============================
  // 공용 스낵바
  // ==============================
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

  void _clearAllSnackBars() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
