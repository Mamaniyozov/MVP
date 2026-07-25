import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/transactions/data/transaction_exception.dart';
import 'package:mobile/features/transactions/domain/transaction_page.dart';

class TransactionRepository {
  TransactionRepository(this._dio);

  final Dio _dio;

  Future<TransactionPage> list({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/transactions/',
        queryParameters: {'page': page},
      );
      return TransactionPage.fromJson(response.data!);
    } on DioException catch (error) {
      throw TransactionException(_networkErrorMessage(error));
    } catch (_) {
      throw const TransactionException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<void> create({
    required int categoryId,
    required int? cardId,
    required double amount,
    required CategoryType type,
    required DateTime date,
    required String note,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/transactions/',
        data: {
          'category': categoryId,
          if (cardId != null) 'card': cardId,
          'amount': amount.toStringAsFixed(2),
          'type': categoryTypeToJson(type),
          'date': _formatDate(date),
          'note': note,
        },
      );
    } on DioException catch (error) {
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
  return TransactionRepository(ref.watch(apiClientProvider));
});
