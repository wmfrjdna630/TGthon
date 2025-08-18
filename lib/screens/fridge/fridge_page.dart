import 'package:flutter/material.dart';
import '../../widgets/common/blue_header.dart'; // green_header에서 blue_header로 변경
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
    // 페이지 종료 시 모든 SnackBar 제거
    _clearAllSnackBars();
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
    return Scaffold(
      // Scaffold로 감싸서 FAB 사용 가능하게 함
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // 상단 헤더 (+ 버튼 제거)
                BlueHeader(
                  icon: Icons.kitchen,
                  title: 'My Fridge',
                  subtitle: '${_filterCounts['All'] ?? 0} items stored',
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
      ),

      // 오른쪽 하단 FAB 추가
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddItemPressed,
        backgroundColor: const Color.fromARGB(255, 30, 0, 255), // 파랑색
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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

  /// 아이템 추가 버튼 처리 (다이얼로그 활성화)
  void _onAddItemPressed() {
    _showAddItemDialog();
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

  /// 아이템 추가 다이얼로그 (새로 추가)
  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedUnit = 'g'; // 기본 단위
    String selectedCategory = '채소'; // 기본 카테고리
    String selectedLocation = 'Fridge'; // 기본 보관위치
    DateTime selectedExpiryDate = DateTime.now().add(
      const Duration(days: 7),
    ); // 기본 1주일 후

    // 사용 가능한 옵션들
    final units = ['g', 'ml', 'kg', 'L', '개', '팩', '병'];
    final categories = [
      '채소',
      '과일',
      '육류',
      '생선',
      '유제품',
      '곡류',
      '조미료',
      '음료',
      '냉동식품',
      '기타',
    ];
    final locations = ['Fridge', 'Freezer', 'Pantry'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color.fromARGB(255, 30, 0, 255),
              ),
              SizedBox(width: 8),
              Text('새 아이템 추가'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이템명 입력
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '아이템명 *',
                    hintText: '예: 양파, 우유, 계란',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.food_bank),
                  ),
                ),

                const SizedBox(height: 16),

                // 수량 + 단위 입력
                Row(
                  children: [
                    // 수량 입력
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '수량 *',
                          hintText: '예: 500',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 단위 선택
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: '단위',
                          border: OutlineInputBorder(),
                        ),
                        items: units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) => setDialogState(() {
                          selectedUnit = value ?? 'g';
                        }),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 카테고리 선택
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() {
                    selectedCategory = value ?? '채소';
                  }),
                ),

                const SizedBox(height: 16),

                // 보관위치 선택
                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: '보관위치',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: locations.map((location) {
                    IconData icon;
                    String label;
                    switch (location) {
                      case 'Freezer':
                        icon = Icons.ac_unit;
                        label = '냉동실';
                        break;
                      case 'Pantry':
                        icon = Icons.home;
                        label = '팬트리';
                        break;
                      default:
                        icon = Icons.kitchen;
                        label = '냉장실';
                    }

                    return DropdownMenuItem(
                      value: location,
                      child: Row(
                        children: [
                          Icon(icon, size: 16),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() {
                    selectedLocation = value ?? 'Fridge';
                  }),
                ),

                const SizedBox(height: 16),

                // 유통기한 선택
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedExpiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      helpText: '유통기한 선택',
                      cancelText: '취소',
                      confirmText: '확인',
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedExpiryDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '유통기한',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${selectedExpiryDate.year}-${selectedExpiryDate.month.toString().padLeft(2, '0')}-${selectedExpiryDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${_calculateDaysLeft(selectedExpiryDate)}일 남음',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getExpiryColor(
                              _calculateDaysLeft(selectedExpiryDate),
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_validateInput(
                  nameController.text,
                  amountController.text,
                )) {
                  Navigator.of(context).pop();
                  _addNewItem(
                    name: nameController.text.trim(),
                    amount: amountController.text.trim(),
                    unit: selectedUnit,
                    category: selectedCategory,
                    location: selectedLocation,
                    expiryDate: selectedExpiryDate,
                  );
                } else {
                  _showErrorSnackBar('아이템명과 수량을 입력해주세요');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 30, 0, 255),
                foregroundColor: Colors.white,
              ),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  /// 입력 검증
  bool _validateInput(String name, String amount) {
    return name.trim().isNotEmpty && amount.trim().isNotEmpty;
  }

  /// 남은 일수 계산
  int _calculateDaysLeft(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// 유통기한에 따른 색상 반환
  Color _getExpiryColor(int daysLeft) {
    if (daysLeft <= 7) return Colors.red;
    if (daysLeft <= 28) return Colors.orange;
    return Colors.green;
  }

  /// 새 아이템 추가 실행
  Future<void> _addNewItem({
    required String name,
    required String amount,
    required String unit,
    required String category,
    required String location,
    required DateTime expiryDate,
  }) async {
    try {
      final daysLeft = _calculateDaysLeft(expiryDate);
      final totalDays = _estimateTotalDays(category);

      final newItem = FridgeItem.fromSampleData(
        name: name,
        amount: '$amount$unit',
        category: category,
        location: location,
        daysLeft: daysLeft,
        totalDays: totalDays,
      );

      await _repository.addFridgeItem(newItem);
      _loadFridgeItems(); // 리스트 새로고침
      _showSuccessSnackBar('$name이(가) 추가되었습니다');
    } catch (e) {
      _showErrorSnackBar('아이템 추가에 실패했습니다');
    }
  }

  /// 카테고리에 따른 예상 총 유통기한 계산
  int _estimateTotalDays(String category) {
    switch (category) {
      case '채소':
      case '과일':
        return 14; // 2주
      case '육류':
      case '생선':
        return 7; // 1주
      case '유제품':
        return 10; // 10일
      case '곡류':
      case '조미료':
        return 365; // 1년
      case '음료':
        return 30; // 1개월
      case '냉동식품':
        return 90; // 3개월
      default:
        return 30; // 기본 1개월
    }
  }

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

  /// 성공 스낵바 (개선됨)
  void _showSuccessSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green,
      duration: const Duration(milliseconds: 1200), // 성공 메시지는 더 짧게
    );
  }

  /// 오류 스낵바 (개선됨)
  void _showErrorSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(milliseconds: 2000), // 오류 메시지는 조금 더 길게
    );
  }

  /// 정보 스낵바 (개선됨)
  void _showInfoSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue.shade600,
      duration: const Duration(milliseconds: 1500), // 정보 메시지는 기본 길이
    );
  }
}
