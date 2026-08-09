import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/storage/offline_cache.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/transactions/data/transaction_exception.dart';
import 'package:mobile/features/transactions/domain/transaction_page.dart';

class TransactionRepository {
  TransactionRepository(this._dio, this._cache);

  final Dio _dio;
  final OfflineCache _cache;

  Future<TransactionPage> list({int page = 1}) async {
    final cacheKey = 'page_$page';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/transactions/',
        queryParameters: {'page': page},
      );
      final data = response.data!;
      await _cache.cacheData(OfflineCache.transactionsBoxName, cacheKey, data);
      return TransactionPage.fromJson(data);
    } on DioException catch (error) {
      // Only a connectivity failure justifies serving stale data; an HTTP
      // error means the server answered and the cache would be misleading.
      if (error.response == null) {
        final cached = _cachedPage(cacheKey);
        if (cached != null) return cached;
      }
      throw TransactionException(_networkErrorMessage(error));
    } catch (_) {
      throw const TransactionException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  TransactionPage? _cachedPage(String cacheKey) {
    final cached = _cache.getCachedData(OfflineCache.transactionsBoxName, cacheKey);
    if (cached is! Map) return null;
    try {
      return TransactionPage.fromJson(Map<String, dynamic>.from(cached));
    } catch (_) {
      return null;
    }
  }

  Future<void> create({
    required int categoryId,
    required int? cardId,
    required int? goalId,
    required double amount,
    required CategoryType type,
    required DateTime date,
    required String note,
  }) async {
    final payload = <String, dynamic>{
      'category': categoryId,
      if (cardId != null) 'card': cardId,
      if (goalId != null) 'goal': goalId,
      'amount': amount.toStringAsFixed(2),
      'type': categoryTypeToJson(type),
      'date': _formatDate(date),
      'note': note,
    };
    try {
      await _dio.post<Map<String, dynamic>>('/api/v1/transactions/', data: payload);
    } on DioException catch (error) {
      if (error.response == null) {
        // Offline: keep the entry so it can be replayed once the device is
        // back online, and tell the user it is pending rather than lost.
        await _cache.enqueueOfflineMutation({
          'method': 'POST',
          'path': '/api/v1/transactions/',
          'body': payload,
        });
        throw const TransactionException(
          "Internet yo'q — tranzaksiya navbatga qo'shildi va aloqa tiklanganda yuboriladi",
        );
      }
      throw TransactionException(_createErrorMessage(error));
    } catch (_) {
      throw const TransactionException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _networkErrorMessage(DioException error) {
    if (error.response != null) {
      return "Ma'lumotlarni yuklab bo'lmadi";
    }
    return "Serverga ulanib bo'lmadi. Internet aloqasini tekshiring";
  }

  String _createErrorMessage(DioException error) {
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
    return "Tranzaksiyani saqlab bo'lmadi";
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    ref.watch(apiClientProvider),
    ref.watch(offlineCacheProvider),
  );
});
