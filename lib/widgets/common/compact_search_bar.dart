import 'package:flutter/material.dart';

class CompactSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final VoidCallback? onFilterPressed;

  const CompactSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.focusNode,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radiusInner = BorderRadius.circular(10); // 회색 검색창 모서리
    final radiusOuter = BorderRadius.circular(16); // 하얀 카드 모서리

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radiusOuter,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: radiusInner,
              ),
              child: ClipRRect(
                borderRadius: radiusInner,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  style: const TextStyle(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center, // ⬅ 세로 중앙
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search Ingredients...',
                    contentPadding: EdgeInsets.zero, // ⬅ 패딩 0
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.grey,
                    ),
                    // ⬅ 아이콘 영역을 높이 40에 맞춰 중앙 정렬
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onFilterPressed != null) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: onFilterPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F4F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune, size: 20, color: Colors.black54),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
