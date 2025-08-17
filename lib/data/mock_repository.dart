import 'dart:async';
import '../models/fridge_item.dart';
import '../models/menu_rec.dart';
import '../models/recipe.dart';
import 'sample_data.dart';

/// 목 데이터 저장소
/// 실제 백엔드 API 대신 로컬 데이터를 관리하는 클래스
/// 추후 실제 API 연동 시 이 클래스를 교체하면 됨
class MockRepository {
  // ========== 싱글톤 패턴 ==========

  static final MockRepository _instance = MockRepository._internal();
  factory MockRepository() => _instance;
  MockRepository._internal();

  // ========== 데이터 스토리지 ==========

  /// 냉장고 아이템들 (수정 가능한 복사본)
  final List<FridgeItem> _fridgeItems = [...SampleData.fridgeItems];

  /// 타임라인용 아이템들 (수정 가능한 복사본)
  final List<FridgeItem> _timelineItems = [...SampleData.timelineItems];

  /// 메뉴 추천들 (수정 가능한 복사본)
  final List<MenuRec> _menuRecommendations = [
    ...SampleData.menuRecommendations,
  ];

  /// 레시피들 (수정 가능한 복사본)
  final List<Recipe> _recipes = [...SampleData.recipes];

  /// 할일 목록
  final List<TodoItem> _todoItems = [
    TodoItem(
      id: '1',
      title: '우유 구매하기',
      description: '유통기한이 내일 만료되는 우유 새로 구매',
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      priority: TodoPriority.high,
    ),
    TodoItem(
      id: '2',
      title: '냉장고 정리하기',
      description: '유통기한 지난 음식들 정리',
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      priority: TodoPriority.medium,
    ),
    TodoItem(
      id: '3',
      title: '저녁 메뉴 계획세우기',
      description: '이번 주 저녁 메뉴 미리 계획',
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      priority: TodoPriority.low,
    ),
  ];

  // ========== 데이터 스트림 컨트롤러들 ==========

  final StreamController<List<FridgeItem>> _fridgeItemsController =
      StreamController<List<FridgeItem>>.broadcast();
  final StreamController<List<Recipe>> _recipesController =
      StreamController<List<Recipe>>.broadcast();
  final StreamController<List<TodoItem>> _todoItemsController =
      StreamController<List<TodoItem>>.broadcast();

  // ========== 스트림 게터들 ==========

  /// 냉장고 아이템 변경 스트림
  Stream<List<FridgeItem>> get fridgeItemsStream =>
      _fridgeItemsController.stream;

  /// 레시피 변경 스트림
  Stream<List<Recipe>> get recipesStream => _recipesController.stream;

  /// 할일 변경 스트림
  Stream<List<TodoItem>> get todoItemsStream => _todoItemsController.stream;

  // ========== 냉장고 아이템 관련 메서드들 ==========

  /// 모든 냉장고 아이템 조회
  Future<List<FridgeItem>> getFridgeItems() async {
    await _simulateNetworkDelay();
    return List.from(_fridgeItems);
  }

  /// 위치별 냉장고 아이템 조회
  Future<List<FridgeItem>> getFridgeItemsByLocation(String location) async {
    await _simulateNetworkDelay();
    if (location == 'All') return List.from(_fridgeItems);
    return _fridgeItems.where((item) => item.location == location).toList();
  }

  /// 타임라인용 아이템 조회
  Future<List<FridgeItem>> getTimelineItems() async {
    await _simulateNetworkDelay();
    return List.from(_timelineItems);
  }

  /// 냉장고 아이템 추가
  Future<void> addFridgeItem(FridgeItem item) async {
    await _simulateNetworkDelay();
    _fridgeItems.add(item);
    _fridgeItemsController.add(List.from(_fridgeItems));
  }

  /// 냉장고 아이템 수정
  Future<void> updateFridgeItem(String itemName, FridgeItem updatedItem) async {
    await _simulateNetworkDelay();
    final index = _fridgeItems.indexWhere((item) => item.name == itemName);
    if (index != -1) {
      _fridgeItems[index] = updatedItem;
      _fridgeItemsController.add(List.from(_fridgeItems));
    }
  }

  /// 냉장고 아이템 삭제
  Future<void> deleteFridgeItem(String itemName) async {
    await _simulateNetworkDelay();
    _fridgeItems.removeWhere((item) => item.name == itemName);
    _fridgeItemsController.add(List.from(_fridgeItems));
  }

  // ========== 메뉴 추천 관련 메서드들 ==========

  /// 모든 메뉴 추천 조회
  Future<List<MenuRec>> getMenuRecommendations() async {
    await _simulateNetworkDelay();
    return List.from(_menuRecommendations);
  }

  /// 정렬된 메뉴 추천 조회
  Future<List<MenuRec>> getSortedMenuRecommendations(String sortBy) async {
    await _simulateNetworkDelay();
    final list = List<MenuRec>.from(_menuRecommendations);

    switch (sortBy) {
      case 'expiry':
        list.sort((a, b) => a.minDaysLeft.compareTo(b.minDaysLeft));
        break;
      case 'frequency':
        list.sort((a, b) => b.frequency.compareTo(a.frequency));
        break;
      case 'favorite':
        list.sort((a, b) {
          if (a.favorite == b.favorite) return a.title.compareTo(b.title);
          return (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
        });
        break;
    }

    return list;
  }

  /// 메뉴 즐겨찾기 토글
  Future<void> toggleMenuFavorite(String menuTitle) async {
    await _simulateNetworkDelay();
    final index = _menuRecommendations.indexWhere(
      (menu) => menu.title == menuTitle,
    );
    if (index != -1) {
      final menu = _menuRecommendations[index];
      _menuRecommendations[index] = menu.copyWith(favorite: !menu.favorite);
    }
  }

  // ========== 레시피 관련 메서드들 ==========

  /// 모든 레시피 조회
  Future<List<Recipe>> getRecipes() async {
    await _simulateNetworkDelay();
    return List.from(_recipes);
  }

  /// 조건별 레시피 필터링
  Future<List<Recipe>> getFilteredRecipes(String filter) async {
    await _simulateNetworkDelay();

    switch (filter) {
      case 'Can make now':
        return _recipes.where((r) => r.canMakeNow).toList();
      case 'Almost ready':
        return _recipes.where((r) => r.isAlmostReady).toList();
      case 'Quick meals':
        return _recipes.where((r) => r.isQuickMeal).toList();
      case 'Vegetarian':
        return _recipes.where((r) => r.isVegetarian).toList();
      default:
        return List.from(_recipes);
    }
  }

  /// 레시피 검색
  Future<List<Recipe>> searchRecipes(String query) async {
    await _simulateNetworkDelay();

    if (query.isEmpty) return List.from(_recipes);

    final lowercaseQuery = query.toLowerCase();
    return _recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(lowercaseQuery) ||
          recipe.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // ========== 할일 관련 메서드들 ==========

  /// 모든 할일 조회
  Future<List<TodoItem>> getTodoItems() async {
    await _simulateNetworkDelay();
    return List.from(_todoItems);
  }

  /// 할일 추가
  Future<void> addTodoItem(TodoItem item) async {
    await _simulateNetworkDelay();
    _todoItems.add(item);
    _todoItemsController.add(List.from(_todoItems));
  }

  /// 할일 완료 상태 토글
  Future<void> toggleTodoCompletion(String itemId) async {
    await _simulateNetworkDelay();
    final index = _todoItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _todoItems[index];
      _todoItems[index] = item.copyWith(
        isCompleted: !item.isCompleted,
        completedAt: !item.isCompleted ? DateTime.now() : null,
      );
      _todoItemsController.add(List.from(_todoItems));
    }
  }

  /// 할일 삭제
  Future<void> deleteTodoItem(String itemId) async {
    await _simulateNetworkDelay();
    _todoItems.removeWhere((item) => item.id == itemId);
    _todoItemsController.add(List.from(_todoItems));
  }

  // ========== 통계 관련 메서드들 ==========

  /// 냉장고 아이템 통계
  Future<Map<String, int>> getFridgeStats() async {
    await _simulateNetworkDelay();

    final stats = <String, int>{
      'total': _timelineItems.length,
      'danger': 0,
      'warning': 0,
      'safe': 0,
    };

    for (final item in _timelineItems) {
      if (item.daysLeft <= 3) {
        stats['danger'] = (stats['danger'] ?? 0) + 1;
      } else if (item.daysLeft <= 7) {
        stats['warning'] = (stats['warning'] ?? 0) + 1;
      } else {
        stats['safe'] = (stats['safe'] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// 레시피 통계
  Future<Map<String, int>> getRecipeStats() async {
    await _simulateNetworkDelay();

    return {
      'total': _recipes.length,
      'canMakeNow': _recipes.where((r) => r.canMakeNow).length,
      'almostReady': _recipes.where((r) => r.isAlmostReady).length,
      'quickMeals': _recipes.where((r) => r.isQuickMeal).length,
      'vegetarian': _recipes.where((r) => r.isVegetarian).length,
    };
  }

  // ========== 유틸리티 메서드들 ==========

  /// 네트워크 지연 시뮬레이션
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// 모든 데이터 초기화
  Future<void> resetAllData() async {
    _fridgeItems.clear();
    _fridgeItems.addAll(SampleData.fridgeItems);

    _timelineItems.clear();
    _timelineItems.addAll(SampleData.timelineItems);

    _menuRecommendations.clear();
    _menuRecommendations.addAll(SampleData.menuRecommendations);

    _recipes.clear();
    _recipes.addAll(SampleData.recipes);

    // 스트림에 변경사항 알림
    _fridgeItemsController.add(List.from(_fridgeItems));
    _recipesController.add(List.from(_recipes));
    _todoItemsController.add(List.from(_todoItems));
  }

  /// 리소스 정리
  void dispose() {
    _fridgeItemsController.close();
    _recipesController.close();
    _todoItemsController.close();
  }
}

// ========== 할일 모델 ==========

/// 할일 아이템 모델
class TodoItem {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final TodoPriority priority;

  const TodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.priority,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    TodoPriority? priority,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
    );
  }
}

/// 할일 우선순위
enum TodoPriority {
  low('낮음'),
  medium('보통'),
  high('높음');

  const TodoPriority(this.label);
  final String label;
}
