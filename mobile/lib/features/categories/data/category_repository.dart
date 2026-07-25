import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/categories/domain/category.dart';

class CategoryRepository {
  CategoryRepository(this._dio);

  final Dio _dio;

  /// Categories are unpaginated on the backend — a plain JSON array.
  Future<List<Category>> list({CategoryType? type}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/categories/',
      queryParameters: type == null ? null : {'type': categoryTypeToJson(type)},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(apiClientProvider));
});
