import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../mock_repository.dart' show TodoItem, TodoPriority;

class TodoRemoteRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No Firebase user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('todos');

  Future<List<TodoItem>> getTodoItems() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  Future<void> addTodoItem(TodoItem item) async {
    await _col.add({
      'title': item.title,
      'description': item.description,
      'isCompleted': item.isCompleted,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'completedAt': item.completedAt == null
          ? null
          : Timestamp.fromDate(item.completedAt!),
      'priority': _priorityToString(item.priority),
    });
  }

  Future<void> toggleTodoCompletion(String itemId) async {
    // 기존 Mock 시그니처(id가 title일 가능성)에 맞춰 title로 찾음
    final byTitle = await _col.where('title', isEqualTo: itemId).limit(1).get();
    if (byTitle.docs.isEmpty) return;
    final doc = byTitle.docs.first;
    final current = (doc.data()['isCompleted'] as bool?) ?? false;
    await doc.reference.update({
      'isCompleted': !current,
      'completedAt': !current ? Timestamp.fromDate(DateTime.now()) : null,
    });
  }

  Future<void> deleteTodoItem(String itemId) async {
    final byTitle = await _col.where('title', isEqualTo: itemId).limit(1).get();
    for (final d in byTitle.docs) {
      await d.reference.delete();
    }
  }

  Stream<List<TodoItem>> streamTodoItems() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  // ===== helpers
  TodoItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return TodoItem(
      id: (m['title'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      isCompleted: (m['isCompleted'] ?? false) as bool,
      createdAt: (m['createdAt'] is Timestamp)
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: (m['completedAt'] is Timestamp)
          ? (m['completedAt'] as Timestamp).toDate()
          : null,
      priority: _stringToPriority((m['priority'] ?? 'medium') as String),
    );
  }

  String _priorityToString(TodoPriority p) => p == TodoPriority.low
      ? 'low'
      : p == TodoPriority.high
      ? 'high'
      : 'medium';

  TodoPriority _stringToPriority(String s) => s == 'low'
      ? TodoPriority.low
      : s == 'high'
      ? TodoPriority.high
      : TodoPriority.medium;
}
