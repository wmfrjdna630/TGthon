import 'package:flutter/material.dart';

class FridgePage extends StatefulWidget {
  const FridgePage({super.key});

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  final FocusNode _focusNode = FocusNode();
  String selectedFilter = 'All';

  // 👉 동적 계산: 보관 위치(location) 기준으로 카운트 산출
  Map<String, int> get filters => {
        'All': items.length,
        'Fridge': items.where((it) => it['location'] == 'Fridge').length,
        'Freezer': items.where((it) => it['location'] == 'Freezer').length,
        'Pantry': items.where((it) => it['location'] == 'Pantry').length,
      };

  // 👉 category(식품군)와 별개로 location(보관 위치) 필드 추가
  final List<Map<String, dynamic>> items = [
    {
      'name': 'Fresh Milk',
      'amount': '1 liter',
      'category': 'Dairy',
      'location': 'Fridge',
      'daysLeft': 3,
      'status': 'Expiring',
      'statusColor': Colors.orange,
      'background': Colors.white,
      'icon': Icons.ac_unit,
      'totalDays': 7,
    },
    {
      'name': 'Chicken Breast',
      'amount': '500g',
      'category': 'Meat',
      'location': 'Fridge',
      'daysLeft': 1,
      'status': 'Use soon',
      'statusColor': Colors.red,
      'background': Colors.white,
      'icon': Icons.ac_unit,
      'totalDays': 3,
    },
    {
      'name': 'Frozen Peas',
      'amount': '300g',
      'category': 'Vegetables',
      'location': 'Freezer',
      'daysLeft': 30,
      'status': 'Fresh',
      'statusColor': Colors.green,
      'background': const Color(0xFFEFF5FF),
      'icon': Icons.ac_unit,
      'totalDays': 90,
    },
    {
      'name': 'Pasta',
      'amount': '500g',
      'category': 'Grains',
      'location': 'Pantry',
      'daysLeft': 180,
      'status': 'Fresh',
      'statusColor': Colors.green,
      'background': const Color(0xFFFFFBE5),
      'icon': Icons.home,
      'totalDays': 365,
    },
    {
      'name': 'Tomatoes',
      'amount': '6 pieces',
      'category': 'Vegetables',
      'location': 'Fridge',
      'daysLeft': 2,
      'status': 'Use soon',
      'statusColor': Colors.red,
      'background': Colors.white,
      'icon': Icons.ac_unit,
      'totalDays': 7,
    },
    {
      'name': 'Ice Cream',
      'amount': '500ml',
      'category': 'Dessert',
      'location': 'Freezer',
      'daysLeft': 45,
      'status': 'Fresh',
      'statusColor': Colors.green,
      'background': const Color(0xFFEFF5FF),
      'icon': Icons.ac_unit,
      'totalDays': 180,
    },
  ];

  List<Map<String, dynamic>> get filteredItems {
    if (selectedFilter == 'All') return items;
    return items.where((item) => item['location'] == selectedFilter).toList();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // 초록 배너
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: const BoxDecoration(
                  color: Color(0xFF34C965),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.kitchen, color: Colors.white),
                            SizedBox(width: 8),
                            Text('My Fridge', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${filters['All']} items stored', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const Positioned(
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Color(0xFF5DCE88),
                        child: Text('+', style: TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),

              // 본문
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // 검색창
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Search ingredients...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFF34C965), width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 필터 버튼
                      _buildFilterBar(),

                      const SizedBox(height: 12),

                      // 아이템 리스트
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: ListView.builder(
                              key: ValueKey<String>(selectedFilter),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return _buildItemCard(item);
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0).withAlpha(77),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: ['All', 'Fridge', 'Freezer', 'Pantry'].map((key) {
          final isSelected = selectedFilter == key;
          final count = filters[key] ?? 0;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0.2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(key, style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black : Colors.grey.shade600,
                    )),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0F0F0).withAlpha(77) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final int totalDays = item['totalDays'] as int? ?? 180;
    final int daysLeft = item['daysLeft'] as int? ?? 0;
    final double progress = (totalDays - daysLeft).clamp(0, totalDays) / totalDays;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item['background'],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(item['category'], style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Icon(item['icon'], size: 16, color: Colors.black45),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${item['amount']} · ${item['location']}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['status'], style: TextStyle(color: item['statusColor'])),
              Text('${daysLeft}d left', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF8F8F8),
              valueColor: AlwaysStoppedAnimation<Color>(item['statusColor']),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}