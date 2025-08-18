import 'package:flutter/material.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/home/expiry_indicator_bar.dart';
import '../../widgets/home/dynamic_header.dart'; // 새로운 동적 헤더 추가
import '../../widgets/home/fridge_timeline.dart';
import '../../widgets/home/menu_recommendations.dart';
import '../../data/sample_data.dart';
import '../../data/mock_repository.dart'; // MockRepository 추가
import '../../models/fridge_item.dart';
import '../../models/menu_rec.dart';

/// 홈페이지 - 메인 대시보드
/// 냉장고 상태, 타임라인, 메뉴 추천 등을 종합적으로 보여주는 페이지
class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, this.userName = '공육공육공'});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 정렬 모드 열거형
enum SortMode { expiry, frequency, favorite }

/// 시간 필터 열거형 (새로운 기준)
enum TimeFilter { week, month, all }

class _HomePageState extends State<HomePage> {
  // ========== 상태 변수들 ==========

  /// 메뉴 정렬 모드
  SortMode _sortMode = SortMode.expiry;

  /// 타임라인 시간 필터 (새로운 기본값)
  TimeFilter _timeFilter = TimeFilter.month;

  /// 검색 텍스트 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  /// 목 데이터 저장소 (즐겨찾기 토글을 위해 추가)
  final MockRepository _repository = MockRepository();

  /// 메뉴 추천 리스트 (Repository를 통해 관리, 초기값은 샘플 데이터)
  List<MenuRec> _menuRecommendations = SampleData.menuRecommendations;

  // ========== 데이터 접근자들 ==========

  /// 샘플 데이터에서 타임라인 아이템 가져오기
  List<FridgeItem> get _allFridgeItems => SampleData.timelineItems;

  /// 시간 필터에 따른 최대 일수 (전체를 1년으로 수정)
  int get _maxDaysForFilter {
    switch (_timeFilter) {
      case TimeFilter.week:
        return 7; // 1주
      case TimeFilter.month:
        return 28; // 1개월 (4주)
      case TimeFilter.all:
        return 365; // 1년 (전체)
    }
  }

  /// 필터링된 냉장고 아이템들 (통합 데이터에서 필터링)
  List<FridgeItem> get _filteredFridgeItems {
    return SampleData.getFridgeItemsByTimeFilter(_maxDaysForFilter);
  }

  /// 정렬된 메뉴 추천들 (actualFrequency 반영)
  List<MenuRec> get _sortedMenus {
    final list = [..._menuRecommendations];
    switch (_sortMode) {
      case SortMode.expiry:
        list.sort((a, b) => a.minDaysLeft.compareTo(b.minDaysLeft));
        break;
      case SortMode.frequency:
        // actualFrequency를 사용하여 클릭 횟수가 반영된 빈도로 정렬
        list.sort((a, b) => b.actualFrequency.compareTo(a.actualFrequency));
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

  // ========== 라이프사이클 메서드들 ==========

  @override
  void initState() {
    super.initState();
    _loadMenuRecommendations();
  }

  @override
  void dispose() {
    // 페이지 종료 시 모든 SnackBar 제거
    _clearAllSnackBars();
    _searchController.dispose();
    super.dispose();
  }

  // ========== 데이터 로딩 ==========

  /// 메뉴 추천 데이터 로딩
  Future<void> _loadMenuRecommendations() async {
    try {
      final menus = await _repository.getMenuRecommendations();
      if (mounted) {
        setState(() {
          _menuRecommendations = menus;
        });
      }
    } catch (e) {
      // 에러 발생 시 샘플 데이터 사용
      setState(() {
        _menuRecommendations = SampleData.menuRecommendations;
      });
    }
  }

  // ========== 빌드 메서드 ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold로 감싸서 FAB 사용 가능하게 함
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 동적 헤더 (새로 추가)
                  DynamicHeader(
                    fridgeItems: _allFridgeItems,
                    menuRecommendations: _sortedMenus,
                    todoCount: 3, // TODO: 실제 TODO 개수로 교체
                  ),

                  const SizedBox(height: 16),

                  // 상단 유통기한 상태 표시바
                  ExpiryIndicatorBar(fridgeItems: _allFridgeItems),

                  const SizedBox(height: 16),

                  // 메인 콘텐츠 영역
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // 검색바
                        CustomSearchBar.home(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),

                        const SizedBox(height: 24),

                        // Quick Actions 삭제됨

                        // 냉장고 타임라인
                        FridgeTimeline(
                          userName: widget.userName,
                          fridgeItems: _filteredFridgeItems,
                          currentFilter: _timeFilter,
                          onFilterChanged: _onTimeFilterChanged,
                        ),

                        const SizedBox(height: 24),

                        // 메뉴 추천 (클릭 이벤트 핸들러 추가)
                        MenuRecommendations(
                          menuRecommendations: _sortedMenus,
                          currentSortMode: _sortMode,
                          onSortModeChanged: _onSortModeChanged,
                          onMenuTapped: _onMenuTapped, // 메뉴 클릭 핸들러
                          onFavoriteToggled: _onFavoriteToggled, // 즐겨찾기 토글 핸들러
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

      // 오른쪽 하단 FAB 추가 (Quick Actions 대체)
      floatingActionButton: FloatingActionButton(
        onPressed: _onQuickActionPressed,
        backgroundColor: const Color.fromARGB(255, 30, 0, 255), // 파랑색
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ========== 이벤트 핸들러들 ==========

  /// 검색 텍스트 변경 처리
  void _onSearchChanged(String query) {
    // TODO: 검색 기능 구현
    // 메뉴나 재료 검색 로직 추가
    setState(() {
      // 검색 결과에 따른 상태 업데이트
    });
  }

  /// 시간 필터 변경 처리
  void _onTimeFilterChanged(TimeFilter newFilter) {
    setState(() {
      _timeFilter = newFilter;
    });
  }

  /// 메뉴 정렬 모드 변경 처리
  void _onSortModeChanged(SortMode newMode) {
    setState(() {
      _sortMode = newMode;
    });
  }

  /// 메뉴 클릭 처리 (빈도 카운트 기능 추가)
  Future<void> _onMenuTapped(MenuRec menu) async {
    try {
      // 1. 먼저 클릭 카운트 증가 (백엔드에 저장)
      await _repository.incrementMenuClick(menu.title);

      // 2. 로컬 상태도 즉시 업데이트 (UI 반응성을 위해)
      setState(() {
        final index = _menuRecommendations.indexWhere(
          (m) => m.title == menu.title,
        );
        if (index != -1) {
          _menuRecommendations[index] = _menuRecommendations[index]
              .incrementClick();
        }
      });

      // 3. 사용자에게 피드백 제공
      _showSuccessSnackBar(
        '${menu.title} 레시피 보기 (클릭: ${menu.clickCount + 1}회)',
      );

      // TODO: 실제 레시피 상세보기 페이지로 이동
      // Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailPage(menu: menu)));
    } catch (e) {
      _showErrorSnackBar('메뉴 정보를 불러오는데 실패했습니다');
    }
  }

  /// 즐겨찾기 토글 처리 (새로 추가)
  Future<void> _onFavoriteToggled(MenuRec menu) async {
    try {
      await _repository.toggleMenuFavorite(menu.title);

      // 로컬 상태도 즉시 업데이트
      setState(() {
        final index = _menuRecommendations.indexWhere(
          (m) => m.title == menu.title,
        );
        if (index != -1) {
          _menuRecommendations[index] = _menuRecommendations[index].copyWith(
            favorite: !_menuRecommendations[index].favorite,
          );
        }
      });

      // 사용자에게 피드백 제공
      final message = menu.favorite
          ? '${menu.title}을(를) 즐겨찾기에서 제거했습니다'
          : '${menu.title}을(를) 즐겨찾기에 추가했습니다';
      _showSuccessSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('즐겨찾기 변경에 실패했습니다');
    }
  }

  // ========== 개선된 스낵바 헬퍼들 ==========

  /// 모든 SnackBar를 즉시 제거하는 메서드
  void _clearAllSnackBars() {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  /// 기존 SnackBar 제거 후 새 SnackBar 표시하는 공통 메서드
  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(milliseconds: 1500), // 기본 1.5초로 단축
  }) {
    if (!mounted) return;

    // 기존 SnackBar를 즉시 제거
    _clearAllSnackBars();

    // 새 SnackBar 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating, // 플로팅 스타일로 더 빠른 반응성
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 성공 스낵바
  void _showSuccessSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green,
      duration: const Duration(milliseconds: 1200), // 성공 메시지는 더 짧게
    );
  }

  /// 오류 스낵바
  void _showErrorSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(milliseconds: 2000), // 오류 메시지는 조금 더 길게
    );
  }

  /// 정보 스낵바
  void _showInfoSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Color.fromARGB(255, 30, 0, 255),
      duration: const Duration(milliseconds: 1500), // 정보 메시지는 기본값
    );
  }

  /// Quick Action FAB 처리 (새로 추가)
  void _onQuickActionPressed() {
    // TODO: Quick Action 선택 다이얼로그 또는 메뉴 표시
    _showQuickActionDialog();
  }

  /// Quick Action 선택 다이얼로그 (새로 추가)
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

            // Add Item 버튼
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color.fromARGB(255, 30, 0, 255),
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Add Item'),
              subtitle: const Text('냉장고에 새 아이템 추가'),
              onTap: () {
                Navigator.pop(context);
                _showInfoSnackBar('아이템 추가 기능');
              },
            ),

            // Scan Receipt 버튼
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color.fromARGB(255, 30, 0, 255),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Scan Receipt'),
              subtitle: const Text('영수증 스캔으로 한 번에 추가'),
              onTap: () {
                Navigator.pop(context);
                _showInfoSnackBar('영수증 스캔 기능');
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
