import 'package:flutter/material.dart';
import '../../widgets/common/blue_header.dart'; // green_header에서 blue_header로 변경
import '../../widgets/common/filter_chips.dart';
import '../../data/mock_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../widgets/common/compact_search_bar.dart';

/// 할일 페이지 - 할일 목록 관리
/// 할일 추가, 완료 처리, 필터링, 검색 기능 제공
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // ========== 상태 변수들 ==========

  /// 현재 선택된 필터
  String _selectedFilter = 'all';

  /// 검색 텍스트 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  /// 목 데이터 저장소
  final MockRepository _repository = MockRepository();

  /// 할일 목록들
  List<TodoItem> _allTodos = [];

  /// 로딩 상태
  bool _isLoading = true;

  // ========== 계산된 속성들 ==========

  /// 필터별 할일 개수
  Map<String, int> get _filterCounts {
    final pending = _allTodos.where((todo) => !todo.isCompleted).length;
    final completed = _allTodos.where((todo) => todo.isCompleted).length;
    final high = _allTodos
        .where(
          (todo) => !todo.isCompleted && todo.priority == TodoPriority.high,
        )
        .length;

    return {
      'all': _allTodos.length,
      'pending': pending,
      'completed': completed,
      'high': high,
    };
  }

  /// 필터링된 할일들
  List<TodoItem> get _filteredTodos {
    List<TodoItem> todos = _allTodos;

    // 상태 필터 적용
    switch (_selectedFilter) {
      case 'pending':
        todos = todos.where((todo) => !todo.isCompleted).toList();
        break;
      case 'completed':
        todos = todos.where((todo) => todo.isCompleted).toList();
        break;
      case 'high':
        todos = todos
            .where(
              (todo) => !todo.isCompleted && todo.priority == TodoPriority.high,
            )
            .toList();
        break;
      case 'all':
      default:
        // 모든 할일 표시
        break;
    }

    // 검색 필터 적용
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      todos = todos.where((todo) {
        return todo.title.toLowerCase().contains(query) ||
            todo.description.toLowerCase().contains(query);
      }).toList();
    }

    // 정렬: 미완료 -> 완료 순, 우선순위 높은 순, 최신 순
    todos.sort((a, b) {
      // 1. 완료 상태 기준 정렬
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // 2. 우선순위 기준 정렬 (높음 > 보통 > 낮음)
      final aPriority = a.priority.index;
      final bPriority = b.priority.index;
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      // 3. 생성일 기준 정렬 (최신 순)
      return b.createdAt.compareTo(a.createdAt);
    });

    return todos;
  }

  // ========== 라이프사이클 메서드들 ==========

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // 페이지 종료 시 모든 SnackBar 제거
    _clearAllSnackBars();
    _searchController.dispose();
    super.dispose();
  }

  // ========== 데이터 로딩 ==========

  /// 할일들 로딩
  Future<void> _loadTodos() async {
    try {
      final todos = await _repository.getTodoItems();
      if (mounted) {
        setState(() {
          _allTodos = todos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('할일을 불러오는데 실패했습니다.');
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
                  icon: Icons.check_box,
                  title: 'To-Do',
                  subtitle: '${_filterCounts['pending'] ?? 0}개의 할일이 남았습니다',
                ),

                // 메인 콘텐츠
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // 검색바
                        CompactSearchBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),

                        const SizedBox(height: 24),

                        // 필터 칩들
                        FilterChips.withCounts(
                          labelCounts: {
                            '전체': _filterCounts['all'] ?? 0,
                            '진행중': _filterCounts['pending'] ?? 0,
                            '완료': _filterCounts['completed'] ?? 0,
                            '긴급': _filterCounts['high'] ?? 0,
                          },
                          selectedLabel: _getFilterLabel(_selectedFilter),
                          onLabelSelected: (label) =>
                              _onFilterChanged(_getFilterKey(label)),
                        ),

                        const SizedBox(height: 16),

                        // 할일 리스트
                        Expanded(child: _buildTodosList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 오른쪽 하단 FAB 추가 (동그라미 모양)
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTodoPressed,
        backgroundColor: const Color(0xFF2196F3), // 파랑색
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 할일 리스트 빌드
  Widget _buildTodosList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredTodos.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredTodos.length,
      itemBuilder: (context, index) {
        final todo = _filteredTodos[index];
        return _TodoCard(
          todo: todo,
          onToggleComplete: () => _onToggleComplete(todo),
          onDelete: () => _onDeleteTodo(todo),
          onTap: () => _onTodoTapped(todo),
        );
      },
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (_searchController.text.isNotEmpty) {
      message = '검색 결과가 없습니다';
      subtitle = '다른 키워드로 검색해보세요';
      icon = Icons.search_off;
    } else {
      switch (_selectedFilter) {
        case 'pending':
          message = '진행중인 할일이 없습니다';
          subtitle = '새로운 할일을 추가해보세요';
          icon = Icons.task_alt;
          break;
        case 'completed':
          message = '완료된 할일이 없습니다';
          subtitle = '할일을 완료하면 여기에 표시됩니다';
          icon = Icons.done_all;
          break;
        case 'high':
          message = '긴급한 할일이 없습니다';
          subtitle = '중요한 일들을 모두 완료했네요!';
          icon = Icons.priority_high;
          break;
        default:
          message = '할일이 없습니다';
          subtitle = '첫 번째 할일을 추가해보세요';
          icon = Icons.add_task;
      }
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          if (_selectedFilter == 'all' && _searchController.text.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onAddTodoPressed,
              icon: const Icon(Icons.add),
              label: const Text('할일 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3), // 파랑색
                foregroundColor: Colors.white,
              ),
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

  /// 필터 변경 처리
  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedFilter = newFilter;
    });
  }

  /// 할일 추가 버튼 처리
  void _onAddTodoPressed() {
    _showAddTodoDialog();
  }

  /// 할일 완료 토글 처리
  Future<void> _onToggleComplete(TodoItem todo) async {
    try {
      await _repository.toggleTodoCompletion(todo.id);
      _loadTodos(); // 리스트 새로고침

      final message = todo.isCompleted ? '할일이 미완료로 변경되었습니다' : '할일이 완료되었습니다!';
      _showSuccessSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('상태 변경에 실패했습니다');
    }
  }

  /// 할일 삭제 처리
  void _onDeleteTodo(TodoItem todo) {
    _showDeleteConfirmDialog(todo);
  }

  /// 할일 탭 처리
  void _onTodoTapped(TodoItem todo) {
    // ignore: todo
    // TODO: 할일 상세보기 또는 편집 다이얼로그
    _showInfoSnackBar('${todo.title} 상세보기');
  }

  // ========== 다이얼로그들 ==========

  /// 할일 추가 다이얼로그
  void _showAddTodoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TodoPriority selectedPriority = TodoPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('새 할일 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '할일 제목',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '상세 설명 (선택사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TodoPriority>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: '우선순위',
                  border: OutlineInputBorder(),
                ),
                items: TodoPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label),
                  );
                }).toList(),
                onChanged: (value) => setDialogState(() {
                  selectedPriority = value ?? TodoPriority.medium;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _addTodo(
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                    selectedPriority,
                  );
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(TodoItem todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할일 삭제'),
        content: Text('${todo.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTodo(todo);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // ========== 데이터 조작 메서드들 ==========

  /// 할일 추가
  Future<void> _addTodo(
    String title,
    String description,
    TodoPriority priority,
  ) async {
    try {
      final newTodo = TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        isCompleted: false,
        createdAt: DateTime.now(),
        priority: priority,
      );

      await _repository.addTodoItem(newTodo);
      _loadTodos(); // 리스트 새로고침
      _showSuccessSnackBar('할일이 추가되었습니다');
    } catch (e) {
      _showErrorSnackBar('할일 추가에 실패했습니다');
    }
  }

  /// 할일 삭제
  Future<void> _deleteTodo(TodoItem todo) async {
    try {
      await _repository.deleteTodoItem(todo.id);
      _loadTodos(); // 리스트 새로고침
      _showSuccessSnackBar('할일이 삭제되었습니다');
    } catch (e) {
      _showErrorSnackBar('삭제에 실패했습니다');
    }
  }

  // ========== 유틸리티 메서드들 ==========

  /// 필터 키를 라벨로 변환
  String _getFilterLabel(String key) {
    switch (key) {
      case 'all':
        return '전체';
      case 'pending':
        return '진행중';
      case 'completed':
        return '완료';
      case 'high':
        return '긴급';
      default:
        return '전체';
    }
  }

  /// 필터 라벨을 키로 변환
  String _getFilterKey(String label) {
    switch (label) {
      case '전체':
        return 'all';
      case '진행중':
        return 'pending';
      case '완료':
        return 'completed';
      case '긴급':
        return 'high';
      default:
        return 'all';
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

  void _showSuccessSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green, // AppColors.success 대신 직접 색상 사용
      duration: const Duration(milliseconds: 1200), // 성공 메시지는 더 짧게
    );
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red, // AppColors.danger 대신 직접 색상 사용
      duration: const Duration(milliseconds: 2000), // 오류 메시지는 조금 더 길게
    );
  }

  void _showInfoSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue.shade600,
      duration: const Duration(milliseconds: 1500), // 정보 메시지는 기본 길이
    );
  }
}

/// 할일 카드 위젯
class _TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TodoCard({
    required this.todo,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggleComplete(),
          activeColor: AppColors.primary,
        ),
        title: Text(
          todo.title,
          style: AppTextStyles.cardTitle.copyWith(
            decoration: todo.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: todo.isCompleted ? Colors.grey : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                todo.description,
                style: AppTextStyles.bodySmallSecondary.copyWith(
                  color: todo.isCompleted ? Colors.grey : null,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                _PriorityChip(priority: todo.priority),
                const SizedBox(width: 8),
                Text(
                  app_date_utils.DateUtils.formatRelativeTime(todo.createdAt),
                  style: AppTextStyles.captionSmall,
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// 우선순위 칩 위젯
class _PriorityChip extends StatelessWidget {
  final TodoPriority priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case TodoPriority.high:
        color = AppColors.danger;
        break;
      case TodoPriority.medium:
        color = AppColors.warning;
        break;
      case TodoPriority.low:
        color = AppColors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
