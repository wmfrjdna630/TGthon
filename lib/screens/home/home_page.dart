// lib/screens/home/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

// ==== 모델 ====
import '../../models/recipe.dart';
import '../../models/menu_rec.dart';
import '../../models/fridge_item.dart';

// ==== 저장소/API ====
import '../../data/recipe_repository.dart';
import '../../data/remote/recipe_api.dart';
import '../../data/remote/fridge_repository.dart';

// ==== 서비스 ====
import '../../services/recipe_ranker.dart';

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
export 'home_types.dart';

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

  // 레시피 API
  late final RecipeRepository _recipeRepo;

  // 냉장고: Firestore 연동
  final FridgeRemoteRepository _fridgeRepo = FridgeRemoteRepository();
  List<FridgeItem> _fridgeItems = [];
  bool _loadingFridge = false;
  StreamSubscription<List<FridgeItem>>? _fridgeSub;

  // 추천/정렬 상태
  SortMode _sortMode = SortMode.expiry;
  TimeFilter _timeFilter = TimeFilter.month;

  // 메뉴/레시피
  List<MenuRec> _menus = [];
  bool _loadingMenus = true;
  List<MenuRec> _allMenus = [];
  Map<String, Recipe> _recipeByTitle = {};
  RecipeRanker? _ranker;

  // ===== 필터/유틸 =====
  int get _maxDaysForFilter {
    switch (_timeFilter) {
      case TimeFilter.week:
        return 7;
      case TimeFilter.month:
        return 28;
      case TimeFilter.third:
        return 90;
    }
  }

  List<FridgeItem> get _filteredFridgeItems =>
      _fridgeItems.where((it) => it.daysLeft <= _maxDaysForFilter).toList();

  @override
  void initState() {
    super.initState();

    // -- API 키 설정: dart-define 우선, 없으면 데모 키 --
    const defineKey = String.fromEnvironment('FOOD_API_KEY');
    const hardKey = 'sample';

    _recipeRepo = RecipeRepository(
      api: RecipeApi(
        base: 'https://openapi.foodsafetykorea.go.kr',
        keyId: (defineKey.isNotEmpty ? defineKey : hardKey),
        serviceId: 'COOKRCP01',
      ),
    );

    // 냉장고 초기 로드 + 실시간 구독
    _initFridge();

    // 레시피/추천 로드
    _loadHomeData();
  }

  Future<void> _initFridge() async {
    setState(() => _loadingFridge = true);
    try {
      // 초기값
      final items = await _fridgeRepo.getFridgeItems();
      if (!mounted) return;
      setState(() {
        _fridgeItems = items;
        _loadingFridge = false;
      });

      // 🔴 Firestore 실시간 구독
      _fridgeSub?.cancel();
      _fridgeSub = _fridgeRepo.watchFridgeItems().listen((items) {
        if (!mounted) return;
        setState(() => _fridgeItems = items);
        // 냉장고 변화 → 추천 재랭킹
        _rankAndSet();
      }, onError: (e) {
        if (!mounted) return;
        _showSnack('냉장고 실시간 연동 오류: $e', Colors.red);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFridge = false);
      _showSnack('냉장고 로드 실패: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    _fridgeSub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== 레시피 로드 & 랭킹 =====
  Future<void> _loadHomeData() async {
    try {
      setState(() => _loadingMenus = true);

      final keyword = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      // 1) 메뉴 수집
      const int pageSize = 100;
      const int maxPages = 50;

      final List<MenuRec> gathered = [];
      for (int page = 1; page <= maxPages; page++) {
        final chunk = await _recipeRepo.searchMenus(
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

      // 2) Recipe 인덱스
      final recipeIndex = <String, Recipe>{};
      for (final m in gathered) {
        final r = m.toRecipe();
        recipeIndex[r.title] = r;
      }

      // 3) 랭커 준비 & 정렬
      _ranker = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );

      final ranked = _ranker!.sortByPriority(
        menus: gathered,
        recipeByTitle: recipeIndex,
      );

      if (!mounted) return;
      setState(() {
        _allMenus = gathered;
        _recipeByTitle = recipeIndex;
        _menus = ranked.take(10).toList();
        _loadingMenus = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('레시피 로드 실패: $e', Colors.red);
      setState(() => _loadingMenus = false);
    }
  }

  // 냉장고가 바뀌었을 때 재랭킹만 수행 (API 재호출 없이)
  void _rankAndSet() {
    if (_allMenus.isEmpty || _recipeByTitle.isEmpty) return;

    _ranker = RecipeRanker(
      fridgeItems: _fridgeItems,
      preferences: const ClickBasedPreference(),
    );

    final ranked = _ranker!.sortByPriority(
      menus: _allMenus,
      recipeByTitle: _recipeByTitle,
    );

    setState(() {
      _menus = ranked.take(10).toList();
    });
  }

  void _onSortModeChanged(SortMode mode) {
    setState(() => _sortMode = mode);
    // 필요시 보조 정렬 추가 가능(지금은 랭커 결과 유지)
  }

  // 레시피 카드 탭 → 상세 화면(기존 시그니처 유지)
  Future<void> _onMenuTapped(MenuRec menu) async {
    try {
      // UI 즉시 반응: 클릭 카운트 증가
      setState(() {
        final idx = _menus.indexOf(menu);
        if (idx >= 0) _menus[idx] = _menus[idx].incrementClick();
      });

      final recipe = _recipeByTitle[menu.title] ?? menu.toRecipe();

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)),
      );

      // 클릭/즐겨찾기가 랭킹에 영향 → 재랭킹
      _rankAndSet();
      _showSnack('${menu.title} 레시피 보기',
          const Color.fromARGB(255, 30, 0, 255));
    } catch (e) {
      _showSnack('레시피 이동 오류: $e', Colors.red);
    }
  }

  // 즐겨찾기 토글 (MenuRecommendations 시그니처 맞춤)
  void _onFavoriteToggled(MenuRec menu) {
    setState(() {
      final idx = _menus.indexOf(menu);
      if (idx >= 0) {
        _menus[idx] = _menus[idx].copyWith(favorite: !menu.favorite);
      }
    });
    _rankAndSet();
  }

  // ===== UI =====
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

                    DynamicHeader(
                      fridgeItems: _fridgeItems,
                      menuRecommendations: _menus,
                      todoCount: 3,
                    ),

                    const SizedBox(height: 16),

                    ExpiryIndicatorBar(fridgeItems: _fridgeItems),

                    const SizedBox(height: 16),

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

                          // 메뉴 추천 리스트
                          _loadingMenus
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : MenuRecommendations(
                                  menuRecommendations: _menus,
                                  currentSortMode: _sortMode,
                                  onSortModeChanged: _onSortModeChanged,
                                  onMenuTapped: _onMenuTapped,
                                  onFavoriteToggled: _onFavoriteToggled,
                                ),

                          const SizedBox(height: 8),

                          // 퀵 액션
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
                                    // TODO: 영수증 스캔 연결 시 구현
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

  // ===== 스낵바 =====
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

  // ===== 퀵 액션: 아이템 추가 =====
  Future<void> _onAddItem() async {
    final newItem = await AddItemDialog.show(context);
    if (newItem == null) return;
    try {
      await _fridgeRepo.addFridgeItem(newItem); // Firestore에 추가
      _showSnack(
        '${newItem.name}이(가) 추가되었습니다',
        const Color.fromARGB(255, 30, 0, 255),
      );
      // 스트림 구독 중이라 자동 반영 + 재랭킹
    } catch (e) {
      _showSnack('아이템 추가 실패: $e', Colors.red);
    }
  }
}
