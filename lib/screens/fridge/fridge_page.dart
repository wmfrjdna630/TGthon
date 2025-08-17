import 'package:flutter/material.dart';
import '../../widgets/common/green_header.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/fridge/fridge_filter_bar.dart';
import '../../widgets/fridge/fridge_item_card.dart';
import '../../data/mock_repository.dart';
import '../../models/fridge_item.dart';

/// 냉장고 페이지 - 보관된 식품들 관리
/// 위치별 필터링, 검색, 아이템 상세보기 등 제공
class FridgePage extends StatefulWidget {
  const FridgePage({super.key});

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  // ========== 상태 변수들 ==========

  /// 현재 선택된 위치 필터
  String _selectedFilter = 'All';

  /// 검색 텍스트 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  /// 검색 입력 포커스 노드
  final FocusNode _focusNode = FocusNode();

  /// 목 데이터 저장소
  final MockRepository _repository = MockRepository();

  /// 냉장고 아이템들
  List<FridgeItem> _allItems = [];

  /// 로딩 상태
  bool _isLoading = true;

  // ========== 계산된 속성들 ==========

  /// 위치별 아이템 개수 맵
  Map<String, int> get _filterCounts => {
    'All': _allItems.length,
    'Fridge': _allItems.where((item) => item.location == 'Fridge').length,
    'Freezer': _allItems.where((item) => item.location == 'Freezer').length,
    'Pantry': _allItems.where((item) => item.location == 'Pantry').length,
  };

  /// 필터링된 아이템들
  List<FridgeItem> get _filteredItems {
    List<FridgeItem> items = _allItems;

    // 위치 필터 적용
    if (_selectedFilter != 'All') {
      items = items.where((item) => item.location == _selectedFilter).toList();
    }

    // 검색 필터 적용
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    return items;
  }

  // ========== 라이프사이클 메서드들 ==========

  @override
  void initState() {
    super.initState();
    _loadFridgeItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ========== 데이터 로딩 ==========

  /// 냉장고 아이템들 로딩
  Future<void> _loadFridgeItems() async {
    try {
      final items = await _repository.getFridgeItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('아이템을 불러오는데 실패했습니다.');
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
              GreenHeader.fridge(
                itemCount: _filterCounts['All'] ?? 0,
                onAddPressed: _onAddItemPressed,
              ),

              // 메인 콘텐츠
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // 검색바
                      CustomSearchBar.fridge(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        focusNode: _focusNode,
                      ),

                      const SizedBox(height: 24),

                      // 위치 필터바
                      FridgeFilterBar(
                        selectedFilter: _selectedFilter,
                        filterCounts: _filterCounts,
                        onFilterChanged: _onFilterChanged,
                      ),

                      const SizedBox(height: 12),

                      // 아이템 리스트
                      Expanded(child: _buildItemsList()),
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

  /// 아이템 리스트 빌드
  Widget _buildItemsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ScrollConfiguration(
        key: ValueKey<String>(_selectedFilter),
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _filteredItems.length,
          itemBuilder: (context, index) {
            final item = _filteredItems[index];
            return FridgeItemCard(
              item: item,
              onTap: () => _onItemTapped(item),
              onEdit: () => _onItemEdit(item),
              onDelete: () => _onItemDelete(item),
            );
          },
        ),
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    String message;
    IconData icon;

    if (_searchController.text.isNotEmpty) {
      message = '검색 결과가 없습니다';
      icon = Icons.search_off;
    } else if (_selectedFilter != 'All') {
      message = '$_selectedFilter에 아이템이 없습니다';
      icon = Icons.inventory_2_outlined;
    } else {
      message = '냉장고가 비어있습니다\n아이템을 추가해보세요';
      icon = Icons.add_circle_outline;
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
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_selectedFilter == 'All' && _searchController.text.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onAddItemPressed,
              icon: const Icon(Icons.add),
              label: const Text('아이템 추가'),
            ),
          ],
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

  /// 위치 필터 변경 처리
  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedFilter = newFilter;
    });
  }

  /// 아이템 추가 버튼 처리
  void _onAddItemPressed() {
    // TODO: 아이템 추가 다이얼로그 또는 페이지 이동
    _showInfoSnackBar('아이템 추가 기능은 준비 중입니다');
  }

  /// 아이템 탭 처리
  void _onItemTapped(FridgeItem item) {
    // TODO: 아이템 상세보기 다이얼로그 또는 페이지 이동
    _showInfoSnackBar('${item.name} 상세보기');
  }

  /// 아이템 수정 처리
  void _onItemEdit(FridgeItem item) {
    // TODO: 아이템 수정 다이얼로그
    _showInfoSnackBar('${item.name} 수정 기능은 준비 중입니다');
  }

  /// 아이템 삭제 처리
  void _onItemDelete(FridgeItem item) {
    _showDeleteConfirmDialog(item);
  }

  // ========== 다이얼로그 및 스낵바 ==========

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(FridgeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아이템 삭제'),
        content: Text('${item.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem(item);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 아이템 삭제 실행
  Future<void> _deleteItem(FridgeItem item) async {
    try {
      await _repository.deleteFridgeItem(item.name);
      _loadFridgeItems(); // 리스트 새로고침
      _showSuccessSnackBar('${item.name}이(가) 삭제되었습니다');
    } catch (e) {
      _showErrorSnackBar('삭제에 실패했습니다');
    }
  }

  /// 성공 스낵바
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

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
