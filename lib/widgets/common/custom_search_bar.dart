import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 공통으로 사용되는 커스텀 검색바 위젯
/// 모든 페이지에서 일관된 검색바 디자인을 제공
class CustomSearchBar extends StatelessWidget {
  final String hintText; // 힌트 텍스트
  final TextEditingController? controller; // 텍스트 컨트롤러
  final ValueChanged<String>? onChanged; // 텍스트 변경 콜백
  final VoidCallback? onSubmitted; // 검색 제출 콜백
  final Widget? trailing; // 우측 위젯 (필터 버튼 등)
  final bool hasWhiteContainer; // 흰색 컨테이너 여부
  final FocusNode? focusNode; // 포커스 노드

  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.hasWhiteContainer = true,
    this.focusNode,
  });

  /// 기본 검색바 (홈페이지용)
  factory CustomSearchBar.home({
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return CustomSearchBar(
      hintText: '메뉴나 재료를 검색하세요...',
      controller: controller,
      onChanged: onChanged,
      hasWhiteContainer: false, // 홈페이지는 심플한 스타일
    );
  }

  /// 냉장고 검색바 (냉장고 페이지용)
  factory CustomSearchBar.fridge({
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
  }) {
    return CustomSearchBar(
      hintText: 'Search ingredients...',
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      hasWhiteContainer: true,
    );
  }

  /// 레시피 검색바 (레시피 페이지용, 필터 버튼 포함)
  factory CustomSearchBar.recipes({
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onFilterPressed,
    FocusNode? focusNode,
  }) {
    return CustomSearchBar(
      hintText: 'Search recipes...',
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      hasWhiteContainer: true,
      trailing: Container(
        decoration: const BoxDecoration(
          color: AppColors.inputBackground,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: onFilterPressed,
          child: const Icon(Icons.tune, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 홈페이지용 심플한 스타일
    if (!hasWhiteContainer) {
      return _buildSimpleSearchBar();
    }

    // 다른 페이지용 카드 스타일
    return _buildCardSearchBar();
  }

  /// 심플한 검색바 (홈페이지용)
  Widget _buildSimpleSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /// 카드 스타일 검색바 (냉장고, 레시피 페이지용)
  Widget _buildCardSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 검색 입력 필드
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // 우측 위젯 (필터 버튼 등)
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// 검색바와 함께 사용되는 필터 버튼
class SearchFilterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isActive;

  const SearchFilterButton({super.key, this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.inputBackground,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: onPressed,
        child: Icon(
          Icons.tune,
          color: isActive ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
