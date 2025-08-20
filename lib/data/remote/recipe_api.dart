// lib/data/remote/recipe_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 식품안전나라 COOKRCP01 전용 간단 API 클라이언트
/// base 예: http://openapi.foodsafetykorea.go.kr
class RecipeApi {
  final String base;
  final String keyId;
  final String serviceId;

  const RecipeApi({
    required this.base,
    required this.keyId,
    this.serviceId = 'COOKRCP01',
  });

  /// startIdx, endIdx는 1-base, 포함구간
  Future<Map<String, dynamic>> fetch({
    required int startIdx,
    required int endIdx,
    String? menuName, // RCP_NM
    String? dishType, // RCP_PAT2
    String? includeParts, // RCP_PARTS_DTLS
    String? changedSinceYmd, // CHNG_DT (YYYYMMDD)
    bool json = true,
  }) async {
    final type = json ? 'json' : 'xml';
    final segments = ['api', keyId, serviceId, type, '$startIdx', '$endIdx'];

    final uri = Uri.parse(base).replace(
      pathSegments: [...Uri.parse(base).pathSegments, ...segments],
      queryParameters: <String, String>{
        if (menuName?.isNotEmpty == true) 'RCP_NM': menuName!,
        if (dishType?.isNotEmpty == true) 'RCP_PAT2': dishType!,
        if (includeParts?.isNotEmpty == true) 'RCP_PARTS_DTLS': includeParts!,
        if (changedSinceYmd?.isNotEmpty == true) 'CHNG_DT': changedSinceYmd!,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Recipe API ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
