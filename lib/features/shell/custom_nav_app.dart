import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../fridge/fridge_page.dart';
import '../recipes/recipes_page.dart';
import '../todo/todo_page.dart';

class CustomNavApp extends StatefulWidget {
  const CustomNavApp({super.key});

  @override
  State<CustomNavApp> createState() => _CustomNavAppState();
}

class _CustomNavAppState extends State<CustomNavApp> {
  int currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    FridgePage(),
    RecipesPage(),
    ToDoPage(),
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
            _navItem(icon: Icons.home, label: 'Home', index: 0),
            _navItem(icon: Icons.kitchen, label: 'Fridge', index: 1),
            _navItem(icon: Icons.book, label: 'Recipes', index: 2),
            _navItem(icon: Icons.check_box, label: 'To-Do', index: 3),
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