import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CustomNavApp(),
    );
  }
}

class CustomNavApp extends StatefulWidget {
  const CustomNavApp({super.key});

  @override
  State<CustomNavApp> createState() => _CustomNavAppState();
}

class _CustomNavAppState extends State<CustomNavApp> {
  int currentIndex = 0; //인덱스 표시

  final List<Widget> _pages = const [
    HomePage(),
    FridgePage(),
    RecipesPage(),
    Center(child: Text("Recipes Page")),
    Center(child: Text("To-Do Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.home, label: "Home", index: 0),
            _navItem(icon: Icons.kitchen, label: "Fridge", index: 1),
            _navItem(icon: Icons.book, label: "Recipes", index: 2),
            _navItem(icon: Icons.check_box, label: "To-Do", index: 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () {
        if (currentIndex != index) {
          setState(() => currentIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF34C965) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            // 상단 초록색 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF34C965),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Hello! 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text("Let's manage your food better today", style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),

            // 본문
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActions(screenHeight),
                    _buildOverview(screenHeight),
                    _buildExpiringNotice(screenHeight),
                    _buildBottomCards(screenHeight),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(double screenHeight) {
    return Container(
      height: screenHeight * 0.16, // 20% 줄인 높이
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.add, color: Colors.green, size: 20),
              SizedBox(width: 6),
              Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 190, // 동일한 너비
                height: 75, // 버튼 높이도 지정
                child: _customActionButton(Icons.add, "Add Item"),
              ),
              SizedBox(
                width: 190,
                height: 75,
                child: _customActionButton(Icons.camera_alt, "Scan Receipt"),
              ),
            ],
          )
        ],
      ),
    );
  }

  static Widget _customActionButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOverview(double screenHeight) {
    return Container(
      height: screenHeight * 0.16,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("\u{1F4C8} Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _overviewItem("12", "Items", Colors.green),
              _overviewItem("3", "Expiring", Colors.orange),
              _overviewItem("24", "Recipes", Colors.teal),
            ],
          )
        ],
      ),
    );
  }

  static Widget _overviewItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildExpiringNotice(double screenHeight) {
    return Container(
      height: screenHeight * 0.17,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 18),
              SizedBox(width: 6),
              Text("Items expiring soon", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text("3 items need your attention."),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: const Text("View Fridge"),
          )
        ],
      ),
    );
  }

  Widget _buildBottomCards(double screenHeight) {
    return Row(
      children: [
        Expanded(child: _cardItem("My Fridge", "12 items", "assets/img/fridge.jpg", screenHeight)),
        const SizedBox(width: 24),
        Expanded(child: _cardItem("Recipes", "24 available", "assets/img/recipe.png", screenHeight)),
      ],
    );
  }

  Widget _cardItem(String title, String subtitle, String imagePath, double screenHeight) {
    return Container(
      height: screenHeight * 0.16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 60), // 기존 80 → 줄임
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

//냉장고

class FridgePage extends StatefulWidget {
  const FridgePage({super.key});

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  final FocusNode _focusNode = FocusNode();
  String selectedFilter = 'All';

  final Map<String, int> filters = {
    'All': 6,
    'Fridge': 3,
    'Freezer': 2,
    'Pantry': 1,
  };

  final List<Map<String, dynamic>> items = [
    {
      'name': 'Fresh Milk',
      'amount': '1 liter',
      'category': 'Dairy',
      'daysLeft': 3,
      'status': 'Expiring',
      'statusColor': Colors.orange,
      'background': Colors.white,
      'icon': Icons.ac_unit,
    },
    {
      'name': 'Chicken Breast',
      'amount': '500g',
      'category': 'Meat',
      'daysLeft': 1,
      'status': 'Use soon',
      'statusColor': Colors.red,
      'background': Colors.white,
      'icon': Icons.ac_unit,
    },
    {
      'name': 'Frozen Peas',
      'amount': '300g',
      'category': 'Vegetables',
      'daysLeft': 30,
      'status': 'Fresh',
      'statusColor': Colors.green,
      'background': const Color(0xFFEFF5FF),
      'icon': Icons.ac_unit,
    },
    {
      'name': 'Pasta',
      'amount': '500g',
      'category': 'Grains',
      'daysLeft': 180,
      'status': 'Fresh',
      'statusColor': Colors.green,
      'background': const Color(0xFFFFFBE5),
      'icon': Icons.home,
    },
    {
      'name': 'Tomatoes',
      'amount': '6 pieces',
      'category': 'Vegetables',
      'daysLeft': 2,
      'status': 'Use soon',
      'statusColor': Colors.red,
      'background': Colors.white,
      'icon': Icons.ac_unit,
    },
    {
      'name': 'Ice Cream',
      'amount': '500ml',
      'category': 'Dessert',
      'daysLeft': 45,
      'status': 'Fresh',
      'statusColor': Colors.green,
      'background': const Color(0xFFEFF5FF),
      'icon': Icons.ac_unit,
    },
  ];

  List<Map<String, dynamic>> get filteredItems {
    if (selectedFilter == 'All') return items;
    return items.where((item) => item['category'] == selectedFilter).toList();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.kitchen, color: Colors.white),
                          SizedBox(width: 8),
                          Text("My Fridge", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text("6 items stored", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Color(0xFF5DCE88),
                      child: Text("+", style: TextStyle(fontSize: 24, color: Colors.white)),
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
                    const SizedBox(height: 24), // 배너와 검색창 간격
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
                            hintText: "Search ingredients...",
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

                    const SizedBox(height: 24), // 검색창과 필터 간격

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
        children: filters.entries.map((entry) {
          final isSelected = selectedFilter == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0.2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(entry.key, style: TextStyle(
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
                      child: Text("${entry.value}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Text(item['amount'], style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['status'], style: TextStyle(color: item['statusColor'])),
              Text("${item['daysLeft']}d left", style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: item['daysLeft'] / 180,
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

//recipe page

import 'package:flutter/material.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade400,
        title: const Text(
          'Recipes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '⭐ 0 ready to cook   🔴 2 almost ready',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.filter_list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 필터 바
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                FilterChip(label: Text('Can make now (0)'), onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: Text('Almost ready (2)'), onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: Text('Quick meals'), onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: Text('Vegetarian'), onSelected: (_) {}),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 레시피 리스트
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12.0),
              children: const [
                RecipeCard(
                  title: 'Fresh Garden Salad',
                  time: '10m',
                  servings: 1,
                  difficulty: 'easy',
                  ingredientsHave: 3,
                  ingredientsTotal: 4,
                ),
                RecipeCard(
                  title: 'Vegetable Soup',
                  time: '45m',
                  servings: 4,
                  difficulty: 'easy',
                  ingredientsHave: 5,
                  ingredientsTotal: 7,
                ),
              ],
            ),
          ),
        ],
      ),

      // 하단 네비게이션
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Recipes 선택 상태
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Fridge'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'To-Do'),
        ],
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final String title;
  final String time;
  final int servings;
  final String difficulty;
  final int ingredientsHave;
  final int ingredientsTotal;

  const RecipeCard({
    super.key,
    required this.title,
    required this.time,
    required this.servings,
    required this.difficulty,
    required this.ingredientsHave,
    required this.ingredientsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ingredientsHave / ingredientsTotal;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 타이틀
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(difficulty, style: const TextStyle(fontSize: 12, color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 시간 및 인원
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(time),
                const SizedBox(width: 12),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('$servings'),
              ],
            ),
            const SizedBox(height: 12),
            // 진행 바
            Text('Ingredients you have'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 4),
            Text('$ingredientsHave/$ingredientsTotal'),
          ],
        ),
      ),
    );
  }
}
