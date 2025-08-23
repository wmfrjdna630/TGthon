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

  // 내부 보조: 전체 후보/인덱스
  List<MenuRec> _allMenus = [];
  Map<String, Recipe> _recipeByTitle = {};
  RecipeRanker? _ranker;

  // 레시피 페이지와 동일 정책: 총 재료 < 15
  static const int _maxRequiredIngredients = 15;

  // ===== 필터/유틸 =====
  /// 현재 선택된 시간 필터에 따른 최대 일수 반환
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

  /// 시간 필터에 따라 필터링된 냉장고 아이템 목록
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

  /// 냉장고 데이터 초기화 및 실시간 구독 설정
  /// Firestore에서 냉장고 데이터를 가져오고 실시간 변경사항을 구독
  Future<void> _initFridge() async {
    setState(() => _loadingFridge = true);
    try {
      // 초기값 로드
      final items = await _fridgeRepo.getFridgeItems();
      if (!mounted) return;

      // 🔴 중요: 초기 데이터 설정 시 setState로 UI 업데이트
      setState(() {
        _fridgeItems = items;
        _loadingFridge = false;
      });

      // 🔴 핵심: Firestore 실시간 구독 설정
      // 냉장고 페이지나 다른 곳에서 수정/추가/삭제 시 자동으로 반영됨
      _fridgeSub?.cancel();
      _fridgeSub = _fridgeRepo.watchFridgeItems().listen(
        (items) {
          if (!mounted) return;

          // 🔴 핵심: 냉장고 데이터 변경 시 즉시 UI 업데이트
          // ExpiryIndicatorBar, FridgeTimeline, DynamicHeader 모두 자동 갱신
          setState(() {
            _fridgeItems = items;
          });

          // 냉장고 변화에 따른 추천 메뉴 재랭킹
          _rankAndSet();
        },
        onError: (e) {
          if (!mounted) return;
          _showSnack('냉장고 실시간 연동 오류: $e', Colors.red);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFridge = false);
      _showSnack('냉장고 로드 실패: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    // 구독 해제
    _fridgeSub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== 공통 유틸: 레시피 페이지와 동일 =====
  /// 임박 냉장고 재료 상위 N개를 include 파라미터로 만들어 API 후보군만 좁힘(개수는 유지)
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

  /// UI 표시용 보유재료 수 — 무조건 냉장고 기준으로 계산
  int _haveCountFromFridge(Recipe r) {
    // 간단 키워드 매칭: 제목 + 태그 텍스트에 냉장고 품목명이 포함되면 보유로 간주
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

  // ===== 레시피 로드 & 랭킹 — 레시피 페이지와 동일한 파이프라인 =====
  /// 홈 화면의 레시피/메뉴 데이터 로드
  Future<void> _loadHomeData() async {
    try {
      setState(() => _loadingMenus = true);

      final keyword = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      // 레시피 페이지와 동일: fetchAll* + include(임박 냉장고 재료 상위 N개)
      final includeParam = _buildIncludeFromFridge(limit: 8);

      // 1) 후보 수집 (전역 컷은 후단에서 적용)
      final recipes = await _recipeRepo.fetchAllRecipes(
        keyword: keyword,
        dishType: null,
        include: includeParam,
        pageSize: 100,
      );
      final menus = await _recipeRepo.fetchAllMenus(
        keyword: keyword,
        dishType: null,
        include: includeParam,
        pageSize: 100,
      );

      // 2) 표시용 보유재료 수치 = 냉장고 기준으로 재산출
      final recipeIndex = <String, Recipe>{};
      for (final r in recipes) {
        final have = _haveCountFromFridge(r);
        recipeIndex[r.title] = r.copyWith(
          ingredientsHave: (r.ingredientsTotal > 0)
              ? have.clamp(0, r.ingredientsTotal)
              : have,
        );
      }

      // 3) 랭커 정렬
      _ranker = RecipeRanker(
        fridgeItems: _fridgeItems,
        preferences: const ClickBasedPreference(),
      );
      List<MenuRec> ranked = _ranker!.sortByPriority(
        menus: menus,
        recipeByTitle: recipeIndex,
      );

      // 4) 레시피 페이지 정책과 동일 적용
      //    - 총 재료 < 15 컷
      //    - have==0(내 재료 없음) 뒤로 밀기
      ranked = ranked.where((m) {
        final r = recipeIndex[m.title];
        if (r == null) return false;
        return r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients;
      }).toList();

      final withHave = <MenuRec>[];
      final withoutHave = <MenuRec>[];
      for (final m in ranked) {
        final have = recipeIndex[m.title]?.ingredientsHave ?? 0;
        (have > 0 ? withHave : withoutHave).add(m);
      }
      final rankedFinal = [...withHave, ...withoutHave];

      if (!mounted) return;
      setState(() {
        _allMenus = rankedFinal;
        _recipeByTitle = recipeIndex;
        // 홈 화면은 상위 10개 노출(기존 UX 유지)
        _menus = rankedFinal.take(10).toList();
        _loadingMenus = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('레시피 로드 실패: $e', Colors.red);
      setState(() => _loadingMenus = false);
    }
  }

  /// 냉장고 데이터가 변경되었을 때 메뉴 추천 재랭킹
  /// API 재호출 없이 기존 데이터로 재정렬만 수행
  void _rankAndSet() {
    if (_allMenus.isEmpty || _recipeByTitle.isEmpty) return;

    // 변경된 냉장고 데이터로 랭커 재생성
    _ranker = RecipeRanker(
      fridgeItems: _fridgeItems,
      preferences: const ClickBasedPreference(),
    );

    // 재랭킹 수행
    List<MenuRec> ranked = _ranker!.sortByPriority(
      menus: _allMenus,
      recipeByTitle: _recipeByTitle,
    );

    // 동일 정책 유지(총 재료 < 15, have==0 뒤)
    ranked = ranked.where((m) {
      final r = _recipeByTitle[m.title];
      if (r == null) return false;
      return r.ingredientsTotal >= 0 && r.ingredientsTotal < _maxRequiredIngredients;
    }).toList();

    final withHave = <MenuRec>[];
    final withoutHave = <MenuRec>[];
    for (final m in ranked) {
      final have = _recipeByTitle[m.title]?.ingredientsHave ?? 0;
      (have > 0 ? withHave : withoutHave).add(m);
    }
    final rankedFinal = [...withHave, ...withoutHave];

    setState(() {
      _allMenus = rankedFinal;
      _menus = rankedFinal.take(10).toList();
    });
  }

  /// 정렬 모드 변경 처리
  void _onSortModeChanged(SortMode mode) {
    setState(() => _sortMode = mode);
    // 필요시 보조 정렬 추가 가능(지금은 랭커 결과 유지)
  }

  /// 메뉴 카드 탭 처리 - 레시피 상세 화면으로 이동
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
      _showSnack('${menu.title} 레시피 보기', const Color.fromARGB(255, 30, 0, 255));
    } catch (e) {
      _showSnack('레시피 이동 오류: $e', Colors.red);
    }
  }

  /// 즐겨찾기 토글 처리
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

                    // 🔴 핵심: DynamicHeader - _fridgeItems를 전달하여 실시간 반영
                    DynamicHeader(
                      fridgeItems: _fridgeItems,
                      menuRecommendations: _menus,
                      todoCount: 3,
                    ),

                    const SizedBox(height: 16),

                    // 🔴 핵심: ExpiryIndicatorBar - _fridgeItems를 전달하여 실시간 반영
                    // 냉장고 데이터가 변경될 때마다 자동으로 업데이트됨
                    ExpiryIndicatorBar(fridgeItems: _fridgeItems),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // 냉장고 타임라인 카드
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
                                      // 로딩 인디케이터
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
                                  // 🔴 핵심: FridgeTimeline - 필터링된 냉장고 아이템 전달
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

                          // 메뉴 추천 리스트 (레시피 페이지와 같은 기준/순서)
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

                          // 퀵 액션 메뉴
                          Align(
                            alignment: Alignment.centerRight,
                            child: PopupMenuButton<void>(
                              tooltip: 'Quick actions',
                              itemBuilder: (context) => <PopupMenuEntry<void>>[
                                PopupMenuItem<void>(
                                  child: const ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        30,
                                        0,
                                        255,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
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
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        30,
                                        0,
                                        255,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
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
      // 플로팅 액션 버튼 - 추천 새로고침
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadHomeData,
        label: const Text('추천 새로고침', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.refresh, color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 30, 0, 255),
      ),
    );
  }

  // ===== 스낵바 유틸리티 =====
  /// 스낵바 표시 헬퍼 메서드
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

  /// 모든 스낵바 제거
  void _clearAllSnackBars() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  // ===== 퀵 액션: 아이템 추가 =====
  /// 냉장고에 새 아이템 추가 처리
  /// Firestore에 추가하면 실시간 구독으로 자동 반영됨
  Future<void> _onAddItem() async {
    final newItem = await AddItemDialog.show(context);
    if (newItem == null) return;
    try {
      // 🔴 핵심: Firestore에 추가하면 watchFridgeItems() 구독으로 자동 반영
      await _fridgeRepo.addFridgeItem(newItem);
      _showSnack(
        '${newItem.name}이(가) 추가되었습니다',
        const Color.fromARGB(255, 30, 0, 255),
      );
      // 별도의 setState나 데이터 갱신 불필요 - 스트림 구독이 자동 처리
    } catch (e) {
      _showSnack('아이템 추가 실패: $e', Colors.red);
    }
  }
}
