// lib/data/remote/fridge_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/fridge_item.dart';

class FridgeRemoteRepository {
  final _fs = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('users').doc(_uid).collection('fridgeItems');

  /// 전체 가져오기 (createdAt 최신순)
  Future<List<FridgeItem>> getFridgeItems() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  /// 위치별 가져오기
  Future<List<FridgeItem>> getFridgeItemsByLocation(String location) async {
    if (location == 'All') return getFridgeItems();
    final snap = await _col.where('location', isEqualTo: location)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  /// 타임라인용 (필요시 정렬/필드 조정)
  Future<List<FridgeItem>> getTimelineItems() async {
    final snap = await _col.orderBy('createdAt', descending: true).limit(50).get();
    return snap.docs.map(_fromDoc).toList();
  }

  /// 추가
  Future<void> addFridgeItem(FridgeItem item) async {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: item.daysLeft)); // AddItemDialog에서 선택한 유통기한을 daysLeft로 계산했던 구조
    await _col.add({
      'name': item.name,
      'amount': item.amount,           // "500g", "2개"처럼 문자열로 보관
      'category': item.category,       // "채소" 등
      'location': item.location,       // "Fridge" | "Freezer" | "Pantry"
      'totalDays': item.totalDays,     // 진행률 계산용
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // 편의상 이름+위치 복합키 보관 (업데이트/삭제 byKey용)
      'key': '${item.name}|${item.location}',
    });
  }

  /// 이름 기준 수정 (기존 시그니처 유지)
  Future<void> updateFridgeItem(String itemName, FridgeItem updated) async {
    final qs = await _col.where('name', isEqualTo: itemName).get();
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: updated.daysLeft));
    for (final d in qs.docs) {
      await d.reference.update({
        'name': updated.name,
        'amount': updated.amount,
        'category': updated.category,
        'location': updated.location,
        'totalDays': updated.totalDays,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
        'key': '${updated.name}|${updated.location}',
      });
    }
  }

  /// 이름+위치 기준 수정 (충돌 줄임)
  Future<void> updateFridgeItemByKey({
    required String originalName,
    required String originalLocation,
    required FridgeItem updatedItem,
  }) async {
    final key = '$originalName|$originalLocation';
    final qs = await _col.where('key', isEqualTo: key).get();
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: updatedItem.daysLeft));
    for (final d in qs.docs) {
      await d.reference.update({
        'name': updatedItem.name,
        'amount': updatedItem.amount,
        'category': updatedItem.category,
        'location': updatedItem.location,
        'totalDays': updatedItem.totalDays,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
        'key': '${updatedItem.name}|${updatedItem.location}',
      });
    }
  }

  /// 이름 기준 삭제 (기존 시그니처 유지)
  Future<void> deleteFridgeItem(String name) async {
    final qs = await _col.where('name', isEqualTo: name).get();
    for (final d in qs.docs) {
      await d.reference.delete();
    }
  }

  /// 이름+위치 기준 삭제 (권장)
  Future<void> deleteFridgeItemByKey(String name, String location) async {
    final key = '$name|$location';
    final qs = await _col.where('key', isEqualTo: key).get();
    for (final d in qs.docs) {
      await d.reference.delete();
    }
  }

  // ========= 내부: 파이어스토어 → 도메인 변환 =========
  FridgeItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    final expiry = (m['expiryDate'] as Timestamp).toDate();
    final daysLeft = expiry
        .difference(DateTime.now())
        .inDays
        .clamp(0, (m['totalDays'] ?? 0) as int? ?? 0);

    // UI 색/아이콘은 모델 내부 팩토리에서 계산하는 기존 패턴 유지
    return FridgeItem.fromSampleData(
      name: (m['name'] ?? '').toString(),
      amount: (m['amount'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      location: (m['location'] ?? 'Fridge').toString(),
      daysLeft: daysLeft,
      totalDays: (m['totalDays'] ?? 30) as int,
    );
  }
}
