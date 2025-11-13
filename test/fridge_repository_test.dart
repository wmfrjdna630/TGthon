import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_work/data/remote/fridge_repository.dart';
import 'package:flutter_work/models/fridge_item.dart';

void main() {
  test('updating one of two items with the same name updates the correct one', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FridgeRemoteRepository(firestore: firestore);

    final item1 = FridgeItem.fromSampleData(
      name: 'Milk',
      amount: '1L',
      category: 'Dairy',
      location: 'Fridge',
      daysLeft: 5,
      totalDays: 10,
    );

    final item2 = FridgeItem.fromSampleData(
      name: 'Milk',
      amount: '2L',
      category: 'Dairy',
      location: 'Fridge',
      daysLeft: 7,
      totalDays: 14,
    );

    await repository.addFridgeItem(item1);
    await repository.addFridgeItem(item2);

    final itemsBeforeUpdate = await repository.getFridgeItems();
    final itemToUpdate = itemsBeforeUpdate.firstWhere((item) => item.amount == '1L');

    final updatedItem = itemToUpdate.copyWith(amount: '500ml');
    await repository.updateFridgeItem(updatedItem);

    final itemsAfterUpdate = await repository.getFridgeItems();
    expect(itemsAfterUpdate.length, 2);
    expect(itemsAfterUpdate.firstWhere((item) => item.id == itemToUpdate.id).amount, '500ml');
    expect(itemsAfterUpdate.firstWhere((item) => item.id != itemToUpdate.id).amount, '2L');
  });
}
