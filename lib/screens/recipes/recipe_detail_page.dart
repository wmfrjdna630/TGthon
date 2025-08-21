// lib/screens/recipes/recipe_detail_page.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe.dart';
import '../../data/recipe_repository.dart';
import '../../data/remote/recipe_api.dart';
import '../../models/api/foodsafety_recipe.dart';
import '../../widgets/common/blue_header.dart';

/// 레시피 상세 페이지 - 통일된 디자인
class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  bool _showNutrition = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasRetried = false;
  String _errorMessage = '';
  FoodSafetyRecipeDto? _recipeDetail;
  late RecipeRepository _repository;

  @override
  void initState() {
    super.initState();

    // API 설정
    const defineKey = String.fromEnvironment('FOOD_API_KEY');
    const hardKey = 'b98006370cc24b529436';

    _repository = RecipeRepository(
      api: RecipeApi(
        base: 'http://openapi.foodsafetykorea.go.kr',
        keyId: (defineKey.isNotEmpty ? defineKey : hardKey),
        serviceId: 'COOKRCP01',
      ),
    );

    _loadRecipeDetail();
  }

  /// 레시피 상세 정보 로드 - 개선된 에러 처리
  Future<void> _loadRecipeDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      print('🔍 API 호출 시작: ${widget.recipe.title}');

      // 🚀 타임아웃과 함께 API 호출
      final unified = await _repository
          .searchUnified(
            keyword: widget.recipe.title,
            page: 1,
            pageSize: 5, // 응답 크기 최소화
          )
          .timeout(
            const Duration(seconds: 8), // 8초 타임아웃
            onTimeout: () => throw Exception('API 응답 시간 초과 (8초)'),
          );

      print('✅ API 응답 성공: ${unified.length}개 결과');

      if (unified.isNotEmpty && mounted) {
        // API 데이터를 활용한 상세 정보 생성
        _createDetailFromApiData(unified.first);
      } else {
        // 빈 응답 시 목 데이터 사용
        print('⚠️ API 응답이 비어있음. 목 데이터 사용');
        _createMockDetailFromRecipe();
      }
    } catch (e) {
      print('❌ API 호출 실패: $e');

      // 🔄 재시도 로직 (한 번만)
      if (!_hasRetried && mounted) {
        _hasRetried = true;
        print('🔄 API 재시도 중...');

        setState(() {
          _errorMessage = '재시도 중...';
        });

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          _loadRecipeDetail();
          return;
        }
      }

      // 🛡️ 최종 실패 시 목 데이터 사용
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getErrorMessage(e);
        });

        _createMockDetailFromRecipe();

        // 3초 후 에러 상태 숨김
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _hasError = false;
            });
          }
        });
      }
    }
  }

  /// API 데이터를 활용한 상세 정보 생성
  void _createDetailFromApiData(dynamic unifiedRecipe) {
    // UnifiedRecipe에서 FoodSafetyRecipeDto 정보 추출
    _recipeDetail = FoodSafetyRecipeDto(
      seq: '1',
      name: widget.recipe.title,
      dishType: _inferDishType(widget.recipe.title),
      hashTag: widget.recipe.tags.map((tag) => '#$tag').join(' '),
      parts: _generateIngredientsParts(widget.recipe),
      imgSmall: null,
      imgLarge: null,
      manuals: _generateCookingSteps(widget.recipe.title),
    );

    setState(() {
      _isLoading = false;
    });

    print('✅ API 기반 상세 정보 생성 완료');
  }

  /// Recipe 정보를 기반으로 목 데이터 생성
  void _createMockDetailFromRecipe() {
    _recipeDetail = FoodSafetyRecipeDto(
      seq: '1',
      name: widget.recipe.title,
      dishType: _inferDishType(widget.recipe.title),
      hashTag: widget.recipe.tags.map((tag) => '#$tag').join(' '),
      parts: _generateIngredientsParts(widget.recipe),
      imgSmall: null,
      imgLarge: null,
      manuals: _generateCookingSteps(widget.recipe.title),
    );

    setState(() {
      _isLoading = false;
    });

    print('🔧 목 데이터 생성 완료');
  }

  /// 에러 메시지 생성
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('시간 초과') || errorStr.contains('timeout')) {
      return '서버 응답 지연';
    } else if (errorStr.contains('네트워크') || errorStr.contains('network')) {
      return '인터넷 연결 확인';
    } else if (errorStr.contains('404') || errorStr.contains('not found')) {
      return '레시피를 찾을 수 없음';
    } else {
      return 'API 연결 실패';
    }
  }

  @override
  void dispose() {
    _hasRetried = false; // 재시도 플래그 리셋
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // 🔥 개선된 BlueHeader with 에러 처리
                BlueHeader(
                  icon: _hasError ? Icons.error_outline : Icons.restaurant_menu,
                  title: _isLoading
                      ? '레시피 로딩 중...'
                      : _hasError
                      ? '연결 문제 발생'
                      : (_recipeDetail?.name ?? widget.recipe.title),
                  subtitle: _isLoading
                      ? (_hasRetried ? '재시도 중...' : '잠시만 기다려주세요')
                      : _hasError
                      ? _errorMessage
                      : '${_recipeDetail?.dishType ?? '기타'} • ${_inferCookingMethod(_recipeDetail?.dishType)}',
                  trailing: _hasError && !_isLoading
                      ? IconButton(
                          onPressed: () {
                            _hasRetried = false;
                            _loadRecipeDetail();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : null,
                ),

                // 메인 콘텐츠
                Expanded(
                  child: _isLoading ? _buildLoadingState() : _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 로딩 상태 위젯 - 개선된 피드백
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 로딩 인디케이터
          CircularProgressIndicator(
            color: _hasRetried ? Colors.orange : AppColors.primary,
          ),
          const SizedBox(height: 16),

          // 상태별 메시지
          Text(
            _hasRetried ? '재시도 중입니다...' : '레시피 정보를 불러오는 중...',
            style: TextStyle(
              fontSize: 16,
              color: _hasRetried ? Colors.orange : Colors.grey,
              fontWeight: _hasRetried ? FontWeight.w600 : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 8),

          // 부가 설명
          Text(
            _hasRetried ? '잠시만 더 기다려주세요' : '서버에서 상세 정보를 가져오고 있습니다',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          // 에러 상태 시 추가 UI
          if (_hasError && _isLoading) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '연결에 문제가 있어 재시도 중입니다',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 메인 콘텐츠
  Widget _buildContent() {
    return Column(
      children: [
        // 🚨 에러 알림 배너 (필요시)
        if (_hasError && !_isLoading) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API 연결 실패',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '기본 정보로 표시됩니다',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _hasRetried = false;
                    _loadRecipeDetail();
                  },
                  child: Text(
                    '재시도',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 메인 스크롤 콘텐츠
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 영양성분 카드
                _buildNutritionCard(),

                const SizedBox(height: 16),

                // 🔥 재료정보 카드
                _buildIngredientsCard(),

                const SizedBox(height: 16),

                // 🔥 만드는 법 카드
                _buildCookingStepsCard(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 영양성분 카드
  Widget _buildNutritionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bar_chart, color: AppColors.primary),
            ),
            title: const Text('영양성분', style: AppTextStyles.sectionTitle),
            trailing: Icon(
              _showNutrition ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
            ),
            onTap: () => setState(() => _showNutrition = !_showNutrition),
          ),
          if (_showNutrition) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildNutritionInfo(),
            ),
          ],
        ],
      ),
    );
  }

  /// 재료정보 카드
  Widget _buildIngredientsCard() {
    final ingredients = FoodSafetyRecipeDto.tokenizeParts(
      _recipeDetail?.parts ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('재료정보', style: AppTextStyles.sectionTitle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.recipe.ingredientsHave}/${widget.recipe.ingredientsTotal}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 재료 상세 정보
          if (_recipeDetail?.parts?.isNotEmpty == true) ...[
            Text(_recipeDetail!.parts!, style: AppTextStyles.body),
            const SizedBox(height: 16),
          ],

          // 재료 태그들
          if (ingredients.isNotEmpty) ...[
            const Text('주요 재료', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredients.take(8).map((ingredient) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.filterSelected,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    ingredient,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '재료 정보를 불러오는 중입니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 만드는 법 카드
  Widget _buildCookingStepsCard() {
    final steps = _recipeDetail?.manuals ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.list_alt, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text('만드는 법', style: AppTextStyles.sectionTitle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${steps.length}단계',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 조리 단계들
          if (steps.isNotEmpty) ...[
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(step, style: AppTextStyles.body),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '조리법 정보를 불러오는 중입니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 영양성분 정보 위젯
  Widget _buildNutritionInfo() {
    Map<String, String> nutrition = _getNutritionByDishType(
      _recipeDetail?.dishType,
    );

    return Column(
      children: nutrition.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key, style: AppTextStyles.body),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🔧 유틸리티 메서드들 (기존과 동일)
  String _inferDishType(String title) {
    if (title.contains('밥')) return '밥';
    if (title.contains('찌개') || title.contains('국')) return '국&찌개';
    if (title.contains('볶음') || title.contains('무침')) return '반찬';
    if (title.contains('케이크') || title.contains('쿠키')) return '후식';
    return '반찬';
  }

  String _inferCookingMethod(String? dishType) {
    switch (dishType) {
      case '밥':
        return '볶음';
      case '국&찌개':
        return '끓임';
      case '반찬':
        return '볶음';
      case '후식':
        return '굽기';
      default:
        return '기타';
    }
  }

  String _generateIngredientsParts(Recipe recipe) {
    if (recipe.title.contains('삼색계란찜')) {
      return '계란 3개, 우유 50ml, 당근 1/4개, 시금치 30g, 소금 약간, 참기름 1작은술, 마늘 1쪽, 양파 1/4개, 대파 1/3대, 치즈 30g, 햄 2장, 후추 약간, 설탕 1/2작은술, 올리브오일 1큰술';
    }
    if (recipe.title.contains('계란')) {
      return '계란 3개, 우유 50ml, 소금 약간, 후추 약간, 파 1대, 기름 1큰술';
    }
    return '재료 정보를 불러오는 중입니다.';
  }

  List<String> _generateCookingSteps(String title) {
    if (title.contains('삼색계란찜')) {
      return [
        '당근과 시금치를 잘게 다지고, 양파와 마늘도 잘게 썬다.',
        '햄을 작은 사각형으로 자르고, 치즈도 잘게 부순다.',
        '계란을 그릇에 깨뜨려 넣고 우유, 소금, 후추, 설탕을 넣어 잘 섞는다.',
        '팬에 올리브오일을 두르고 마늘과 양파를 볶아 향을 낸다.',
        '당근과 시금치를 넣고 살짝 볶은 후 식힌다.',
        '계란물에 볶은 채소와 햄, 치즈를 넣고 잘 섞는다.',
        '찜기에 그릇을 넣고 15-20분간 쪄서 완성한다.',
      ];
    }

    if (title.contains('계란')) {
      return [
        '계란을 그릇에 깨뜨려 넣고 우유, 소금, 후추를 넣어 잘 섞는다.',
        '파는 송송 썰어 계란물에 넣는다.',
        '팬에 기름을 두르고 중약불로 달군다.',
        '계란물을 팬에 부어 젓가락으로 저으며 익힌다.',
        '계란이 반숙 정도로 익으면 불을 끄고 완성한다.',
      ];
    }

    return ['재료를 준비합니다.', '조리 과정을 진행합니다.', '맛있게 완성합니다.'];
  }

  Map<String, String> _getNutritionByDishType(String? dishType) {
    switch (dishType) {
      case '밥':
        return {
          '칼로리': '320 kcal',
          '탄수화물': '65g',
          '단백질': '8g',
          '지방': '3g',
          '나트륨': '800mg',
        };
      case '국&찌개':
        return {
          '칼로리': '150 kcal',
          '탄수화물': '12g',
          '단백질': '15g',
          '지방': '5g',
          '나트륨': '1200mg',
        };
      case '반찬':
        return {
          '칼로리': '180 kcal',
          '탄수화물': '8g',
          '단백질': '12g',
          '지방': '11g',
          '나트륨': '520mg',
        };
      default:
        return {
          '칼로리': '200 kcal',
          '탄수화물': '20g',
          '단백질': '10g',
          '지방': '8g',
          '나트륨': '600mg',
        };
    }
  }
}
