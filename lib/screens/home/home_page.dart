import 'package:flutter/material.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/home/expiry_indicator_bar.dart';
import '../../widgets/home/quick_actions_card.dart';
import '../../widgets/home/fridge_timeline.dart';
import '../../widgets/home/menu_recommendations.dart';
import '../../data/sample_data.dart';
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

/// 시간 필터 열거형
enum TimeFilter { week, biweek, month }

class _HomePageState extends State<HomePage> {
  // ========== 상태 변수들 ==========

  /// 메뉴 정렬 모드
  SortMode _sortMode = SortMode.expiry;

  /// 타임라인 시간 필터
  TimeFilter _timeFilter = TimeFilter.biweek;

  /// 검색 텍스트 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // ========== 데이터 접근자들 ==========

  /// 샘플 데이터에서 타임라인 아이템 가져오기
  List<FridgeItem> get _allFridgeItems => SampleData.timelineItems;

  /// 샘플 데이터에서 메뉴 추천 가져오기
  List<MenuRec> get _menuRecommendations => SampleData.menuRecommendations;

  /// 시간 필터에 따른 최대 일수
  int get _maxDaysForFilter {
    switch (_timeFilter) {
      case TimeFilter.week:
        return 7;
      case TimeFilter.biweek:
        return 14;
      case TimeFilter.month:
        return 30;
    }
  }

  /// 필터링된 냉장고 아이템들
  List<FridgeItem> get _filteredFridgeItems {
    return _allFridgeItems
        .where((item) => item.daysLeft <= _maxDaysForFilter)
        .toList();
  }

  /// 정렬된 메뉴 추천들
  List<MenuRec> get _sortedMenus {
    final list = [..._menuRecommendations];
    switch (_sortMode) {
      case SortMode.expiry:
        list.sort((a, b) => a.minDaysLeft.compareTo(b.minDaysLeft));
        break;
      case SortMode.frequency:
        list.sort((a, b) => b.frequency.compareTo(a.frequency));
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== 빌드 메서드 ==========

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
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

                      // 빠른 액션 카드
                      const QuickActionsCard(),

                      const SizedBox(height: 24),

                      // 냉장고 타임라인
                      FridgeTimeline(
                        userName: widget.userName,
                        fridgeItems: _filteredFridgeItems,
                        currentFilter: _timeFilter,
                        onFilterChanged: _onTimeFilterChanged,
                      ),

                      const SizedBox(height: 24),

                      // 메뉴 추천
                      MenuRecommendations(
                        menuRecommendations: _sortedMenus,
                        currentSortMode: _sortMode,
                        onSortModeChanged: _onSortModeChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
}
