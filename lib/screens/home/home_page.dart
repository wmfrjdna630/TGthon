// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';

// ==== UI 위젯들 ====
import '../../widgets/home/expiry_indicator_bar.dart';
import '../../widgets/home/dynamic_header.dart';
import '../../widgets/home/fridge_timeline.dart';
import '../../widgets/home/menu_recommendations.dart';
import '../../widgets/common/add_item_dialog.dart';

// ==== 데이터/모델 ====
import '../../data/sample_data.dart';
import '../../data/remote/recipe_api.dart';
import '../../data/recipe_repository.dart';
import '../../data/mock_repository.dart'; // Add Item 등 로컬 목 동작에 사용
import '../../models/fridge_item.dart';
import '../../models/menu_rec.dart';

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

  List<MenuRec> _menus = [];
  bool _loadingMenus = true;

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
        base: 'http://openapi.foodsafetykorea.go.kr',
        keyId: (defineKey.isNotEmpty ? defineKey : hardKey),
        serviceId: 'COOKRCP01',
      ),
    );

    _loadMenus(); // 최초 로드
  }

  @override
  void dispose() {
    _clearAllSnackBars();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== 데이터 로드 =====
  Future<void> _loadMenus() async {
    try {
      setState(() => _loadingMenus = true);

      final keyword = _searchController.text.trim();
      final menus = await _recipeRepo.searchMenus(
        keyword: keyword.isEmpty ? null : keyword, // RCP_NM
        dishType: null, // 홈은 전체
        include: null, // 필요시 대표 재료(예: '계란')로 1차 필터 가능
        page: 1,
        pageSize: 20,
      );

      if (!mounted) return;
      setState(() {
        _menus = _applySort(menus, _sortMode);
        _loadingMenus = false;
      });
    } catch (_) {
      // 실패 시 샘플 폴백
      if (!mounted) return;
      setState(() {
        _menus = _applySort(SampleData.menuRecommendations, _sortMode);
        _loadingMenus = false;
      });
      _showSnack('레시피 API 호출 실패. 샘플 데이터로 표시합니다.', Colors.orange);
    }
  }

  // ===== 정렬 =====
  List<MenuRec> _applySort(List<MenuRec> src, SortMode mode) {
    final owned = _allFridgeItems
        .map((e) => e.name.trim().toLowerCase())
        .toSet();

    var list = List<MenuRec>.from(src);
    switch (mode) {
      case SortMode.expiry:
        list.sort((a, b) => a.minDaysLeft.compareTo(b.minDaysLeft));
        break;

      case SortMode.frequency:
        int missing(MenuRec m) => _missingRequiredCount(m, owned);
        list = list.where((m) => missing(m) < 3).toList()
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

      case SortMode.favorite:
        list.sort((a, b) {
          if (a.favorite == b.favorite) return a.title.compareTo(b.title);
          return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
        });
        break;
    }
    return list;
  }

  // 홈/레시피 공통 “부족 개수” 계산기
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
                                menuRecommendations: _applySort(
                                  _menus,
                                  _sortMode,
                                ),
                                currentSortMode: _sortMode,
                                onSortModeChanged: (m) =>
                                    setState(() => _sortMode = m),
                                onMenuTapped: (menu) {
                                  // 클릭수/최근성 로컬 반영
                                  setState(() {
                                    final idx = _menus.indexOf(menu);
                                    if (idx >= 0) {
                                      _menus[idx] = _menus[idx]
                                          .incrementClick();
                                    }
                                  });
                                  _showSnack(
                                    '${menu.title} 상세로 이동',
                                    const Color.fromARGB(255, 30, 0, 255),
                                  );
                                },
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
