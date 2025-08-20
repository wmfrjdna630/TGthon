// lib/widgets/common/edit_item_dialog.dart
import 'package:flutter/material.dart';
import '../../../models/fridge_item.dart';

class EditItemDialog extends StatefulWidget {
  final FridgeItem item;

  const EditItemDialog({super.key, required this.item});

  static Future<FridgeItem?> show(BuildContext context, FridgeItem item) {
    return showDialog<FridgeItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditItemDialog(item: item),
    );
  }

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _daysLeftCtrl;
  late TextEditingController _totalDaysCtrl;

  String _location = 'Fridge';

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _nameCtrl = TextEditingController(text: it.name);
    _amountCtrl = TextEditingController(text: it.amount);
    _categoryCtrl = TextEditingController(text: it.category);
    _daysLeftCtrl = TextEditingController(text: it.daysLeft.toString());
    _totalDaysCtrl = TextEditingController(text: it.totalDays.toString());
    _location = it.location;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _daysLeftCtrl.dispose();
    _totalDaysCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final amount = _amountCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final location = _location;
    final daysLeft = int.tryParse(_daysLeftCtrl.text.trim()) ?? 0;
    final totalDays = int.tryParse(_totalDaysCtrl.text.trim()) ?? 0;

    final updated = FridgeItem.fromSampleData(
      name: name,
      amount: amount,
      category: category,
      location: location,
      daysLeft: daysLeft,
      totalDays: totalDays,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('아이템 수정'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '이름'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: '수량'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(labelText: '카테고리'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _location,
                  items: const [
                    DropdownMenuItem(value: 'Fridge', child: Text('Fridge')),
                    DropdownMenuItem(value: 'Freezer', child: Text('Freezer')),
                    DropdownMenuItem(value: 'Pantry', child: Text('Pantry')),
                  ],
                  onChanged: (v) => setState(() => _location = v ?? 'Fridge'),
                  decoration: const InputDecoration(labelText: '보관 위치'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _daysLeftCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '남은 유통기한(일)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return '0 이상 정수를 입력';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _totalDaysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '전체 유통기한(일)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return '1 이상 정수를 입력';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
