import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/storage/offline_cache.dart';
import 'package:mobile/features/categories/data/category_exception.dart';
import 'package:mobile/features/categories/domain/category.dart';

class CategoryRepository {
  CategoryRepository(this._dio, this._cache);

  final Dio _dio;
  final OfflineCache _cache;

  /// Categories are unpaginated on the backend — a plain JSON array.
  Future<List<Category>> list({CategoryType? type}) async {
    final cacheKey = type == null ? 'all' : categoryTypeToJson(type);
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/categories/',
        queryParameters: type == null ? null : {'type': categoryTypeToJson(type)},
      );
      final data = response.data!;
      await _cache.cacheData(OfflineCache.categoriesBoxName, cacheKey, data);
      return data.cast<Map<String, dynamic>>().map(Category.fromJson).toList();
    } on DioException catch (error) {
      // Serve the cache only when the server was unreachable at all.
      if (error.response == null) {
        final cached = _cachedList(cacheKey);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  List<Category>? _cachedList(String cacheKey) {
    final cached = _cache.getCachedData(OfflineCache.categoriesBoxName, cacheKey);
    if (cached is! List) return null;
    try {
      return cached
          .map((item) => Category.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> create({required String name, required CategoryType type, String icon = ''}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/categories/',
        data: {'name': name, 'type': categoryTypeToJson(type), 'icon': icon},
      );
    } on DioException catch (error) {
      throw CategoryException(_writeErrorMessage(error, "Kategoriyani saqlab bo'lmadi"));
    } catch (_) {
      throw const CategoryException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<void> update({
    required int id,
    required String name,
    required CategoryType type,
    String icon = '',
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/v1/categories/$id/',
        data: {'name': name, 'type': categoryTypeToJson(type), 'icon': icon},
      );
    } on DioException catch (error) {
      throw CategoryException(_writeErrorMessage(error, "Kategoriyani saqlab bo'lmadi"));
    } catch (_) {
      throw const CategoryException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/api/v1/categories/$id/');
    } on DioException catch (error) {
      throw CategoryException(_writeErrorMessage(error, "Kategoriyani o'chirib bo'lmadi"));
    } catch (_) {
      throw const CategoryException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  String _writeErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data.isNotEmpty) {
      final firstError = data.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      if (firstError is String) {
        return firstError;
      }
    }
    if (error.response == null) {
      return "Serverga ulanib bo'lmadi. Internet aloqasini tekshiring";
    }
    return fallback;
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(apiClientProvider),
    ref.watch(offlineCacheProvider),
  );
});
