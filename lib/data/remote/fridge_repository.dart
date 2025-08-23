// lib/data/remote/fridge_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/fridge_item.dart';

class FridgeRemoteRepository {
  final _fs = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('users').doc(_uid).collection('fridgeItems');

  // =========================
  // READ
  // =========================
  /// 전체 가져오기 (createdAt 최신순)
  Future<List<FridgeItem>> getFridgeItems() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  /// 실시간 구독 (홈 자동 반영)
  Stream<List<FridgeItem>> watchFridgeItems() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  // =========================
  // CREATE
  // =========================
  /// 객체 기반 추가 (기존 호출과 호환)
  Future<void> addFridgeItem(FridgeItem item) async {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: item.daysLeft));

    await _col.add({
      'name': item.name,
      'amount': item.amount,           // "500g", "2개" 등 문자열
      'category': item.category,       // "채소" 등
      'location': item.location,       // "Fridge" | "Freezer" | "Pantry"
      'totalDays': item.totalDays,     // 진행률 계산용
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'key': '${item.name}|${item.location}',
    });
  }

  // =========================
  // UPDATE
  // =========================
  /// (1) 이름 + 변경필드 맵 기반 업데이트
  Future<void> updateFridgeItem(String name, Map<String, dynamic> data) async {
    final q = await _col.where('name', isEqualTo: name).get();
    for (final d in q.docs) {
      await d.reference.update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
     /// (3) 이름 변경을 포함한 업데이트 (oldName 기준 문서 탐색)
  Future<void> updateFridgeItemByOldName({
    required String oldName,
    required FridgeItem updated,
  }) async {
    final q = await _col.where('name', isEqualTo: oldName).limit(1).get();
    if (q.docs.isEmpty) return;
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: updated.daysLeft));
    final ref = q.docs.first.reference;
    await ref.update({
      'name': updated.name,                // ← 새 이름으로 실제 문서 갱신
      'amount': updated.amount,
      'category': updated.category,
      'location': updated.location,
      'totalDays': updated.totalDays, 'expiryDate': Timestamp.fromDate(expiryDate),
      'key': '${updated.name}|${updated.location}', // 기존 key 규칙도 갱신
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// (2) 객체 기반 업데이트 (기존 호출과 호환)
  Future<void> updateFridgeItemObject(FridgeItem item) async {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: item.daysLeft));

    await updateFridgeItem(item.name, {
      'amount': item.amount,
      'category': item.category,
      'location': item.location,
      'totalDays': item.totalDays,
      'expiryDate': Timestamp.fromDate(expiryDate),
    });
  }

  // =========================
  // DELETE
  // =========================
  /// (1) 이름 기반 삭제
  Future<void> deleteFridgeItem(String name) async {
    final q = await _col.where('name', isEqualTo: name).get();
    for (final d in q.docs) {
      await d.reference.delete();
    }
  }

  /// (2) 객체 기반 삭제 (기존 호출과 호환)
  Future<void> deleteFridgeItemObject(FridgeItem item) =>
      deleteFridgeItem(item.name);

  // =========================
  // MAPPER
  // =========================
  FridgeItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final ts = m['expiryDate'] as Timestamp?;
    final expiry = ts?.toDate() ?? DateTime.now();
    final now = DateTime.now();
    final int totalDays = (m['totalDays'] ?? 30) as int;
    final int daysLeft = expiry.difference(now).inDays.clamp(0, totalDays);

    // UI 색/아이콘 계산은 기존 팩토리 유지
    return FridgeItem.fromSampleData(
      name: (m['name'] ?? '').toString(),
      amount: (m['amount'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      location: (m['location'] ?? 'Fridge').toString(),
      daysLeft: daysLeft,
      totalDays: totalDays,
    );
  }
}
