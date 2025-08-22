// lib/screens/fridge/fridge_page.dart

import 'package:flutter/material.dart';
import '../../widgets/common/blue_header.dart';
import '../../widgets/fridge/fridge_filter_bar.dart';
import '../../widgets/fridge/fridge_item_card.dart';
import '../../data/remote/fridge_repository.dart';
import '../../models/fridge_item.dart';
import '../../widgets/common/add_item_dialog.dart';
import '../../widgets/common/compact_search_bar.dart';
import '../../widgets/common/edit_item_dialog.dart'; // [추가]

class FridgePage extends StatefulWidget {
  const FridgePage({super.key});

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FridgeRemoteRepository _repository = FridgeRemoteRepository();

  List<FridgeItem> _allItems = [];
  bool _isLoading = true;

  Map<String, int> get _filterCounts => {
    'All': _allItems.length,
    'Fridge': _allItems.where((item) => item.location == 'Fridge').length,
    'Freezer': _allItems.where((item) => item.location == 'Freezer').length,
    'Pantry': _allItems.where((item) => item.location == 'Pantry').length,
  };

  List<FridgeItem> get _filteredItems {
    List<FridgeItem> items = _allItems;
    if (_selectedFilter != 'All') {
      items = items.where((item) => item.location == _selectedFilter).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _loadFridgeItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _clearAllSnackBars();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
        setState(() => _isLoading = false);
        _showErrorSnackBar('불러오기 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                BlueHeader(
                  icon: Icons.kitchen,
                  title: '나의 냉장고',
                  subtitle: '${_filterCounts['All'] ?? 0} 개의 재료가 있어요!',
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        CompactSearchBar(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: _onSearchChanged,
                        ),
                        const SizedBox(height: 24),
                        FridgeFilterBar(
                          selectedFilter: _selectedFilter,
                          filterCounts: _filterCounts,
                          onFilterChanged: _onFilterChanged,
                        ),
                        const SizedBox(height: 12),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddItemPressed,
        backgroundColor: const Color.fromARGB(255, 30, 0, 255),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredItems.isEmpty) return _buildEmptyState();

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
              onEdit: () => _onItemEdit(item), // [구현]
              onDelete: () => _onItemDelete(item), // [구현]
            );
          },
        ),
      ),
    );
  }

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 30, 0, 255),
                foregroundColor: Colors.white,
              ),
              onPressed: _onAddItemPressed,
              icon: const Icon(Icons.add),
              label: const Text('아이템 추가'),
            ),
          ],
        ],
      ),
    );
  }

  // ===== 이벤트 핸들러 =====

  void _onSearchChanged([String? _]) => setState(() {});

  void _onFilterChanged(String newFilter) {
    setState(() => _selectedFilter = newFilter);
  }

  void _onAddItemPressed() async {
    final newItem = await AddItemDialog.show(context);
    if (newItem != null) {
      try {
        await _repository.addFridgeItem(newItem);
        await _loadFridgeItems();
        _showSuccessSnackBar('${newItem.name}이(가) 추가되었습니다');
      } catch (e) {
        _showErrorSnackBar('추가 실패: $e');
      }
    }
  }

  void _onItemTapped(FridgeItem item) {
    _showInfoSnackBar('${item.name} 상세보기');
  }

  /// [변경] 실제 수정 로직 구현: 다이얼로그 → 저장 → 새로고침
  Future<void> _onItemEdit(FridgeItem item) async {
    final updated = await EditItemDialog.show(context, item);
    if (updated == null) return;

    try {
      // 기존 시그니처 호환: (name, updatedItem)
      await _repository.updateFridgeItem(item.name, updated);
      await _loadFridgeItems();
      _showSuccessSnackBar('${item.name}이(가) 수정되었습니다');
    } catch (e) {
      _showErrorSnackBar('수정 실패: $e');
    }
  }

  void _onItemDelete(FridgeItem item) {
    _showDeleteConfirmDialog(item);
  }

  // ===== 다이얼로그 & 스낵바 =====

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
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteItem(item);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(FridgeItem item) async {
    try {
      // 기본: 이름으로 삭제(기존 시그니처 유지)
      await _repository.deleteFridgeItem(item.name);

      // 만약 동명이인/중복우려가 있으면 아래로 교체 가능:
      // await _repository.deleteFridgeItemByKey(item.name, item.location);

      await _loadFridgeItems();
      _showSuccessSnackBar('${item.name}이(가) 삭제되었습니다');
    } catch (e) {
      _showErrorSnackBar('삭제 실패: $e');
    }
  }

  void _clearAllSnackBars() {
    if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    if (!mounted) return;
    _clearAllSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) => _showSnackBar(
    message: message,
    backgroundColor: const Color.fromARGB(255, 30, 0, 255),
    duration: const Duration(milliseconds: 1200),
  );

  void _showErrorSnackBar(String message) => _showSnackBar(
    message: message,
    backgroundColor: Colors.red,
    duration: const Duration(milliseconds: 2000),
  );

  void _showInfoSnackBar(String message) => _showSnackBar(
    message: message,
    backgroundColor: const Color.fromARGB(255, 30, 0, 255),
  );
}
