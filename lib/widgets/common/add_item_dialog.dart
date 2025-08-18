import 'package:flutter/material.dart';
import '../../models/fridge_item.dart';

class AddItemDialog {
  static Future<FridgeItem?> show(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    String selectedUnit = 'g';
    String selectedCategory = '채소';
    String selectedLocation = 'Fridge';
    DateTime selectedExpiryDate = DateTime.now().add(const Duration(days: 7));

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

    return showDialog<FridgeItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '수량 *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: '단위',
                          border: OutlineInputBorder(),
                        ),
                        items: units
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedUnit = value ?? 'g'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedCategory = value ?? '채소'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: '보관위치',
                    border: OutlineInputBorder(),
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
                  onChanged: (value) => setDialogState(
                    () => selectedLocation = value ?? 'Fridge',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedExpiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedExpiryDate = picked);
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
                        Text(
                          "${selectedExpiryDate.year}-${selectedExpiryDate.month.toString().padLeft(2, '0')}-${selectedExpiryDate.day.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 16),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 30, 0, 255),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    amountController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(
                  context,
                  FridgeItem.fromSampleData(
                    name: nameController.text.trim(),
                    amount: '${amountController.text.trim()}$selectedUnit',
                    category: selectedCategory,
                    location: selectedLocation,
                    daysLeft: selectedExpiryDate
                        .difference(DateTime.now())
                        .inDays,
                    totalDays: 30, // 이 부분은 외부에서 조정 가능
                  ),
                );
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}
