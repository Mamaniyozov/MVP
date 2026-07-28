import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/goals/data/goal_exception.dart';
import 'package:mobile/features/goals/domain/goal.dart';

class GoalRepository {
  GoalRepository(this._dio);

  final Dio _dio;

  /// Goals are unpaginated on the backend — a plain JSON array.
  Future<List<Goal>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/v1/goals/');
      return response.data!.cast<Map<String, dynamic>>().map(Goal.fromJson).toList();
    } on DioException catch (error) {
      throw GoalException(_networkErrorMessage(error));
    } catch (_) {
      throw const GoalException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<void> create({
    required String name,
    required double targetAmount,
    required DateTime? deadline,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/goals/',
        data: {
          'name': name,
          'target_amount': targetAmount.toStringAsFixed(2),
          if (deadline != null) 'deadline': _formatDate(deadline),
        },
      );
    } on DioException catch (error) {
      throw GoalException(_writeErrorMessage(error, "Maqsadni saqlab bo'lmadi"));
    } catch (_) {
      throw const GoalException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<void> addProgress({required int goalId, required double amount}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/goals/$goalId/add-progress/',
        data: {'amount': amount.toStringAsFixed(2)},
      );
    } on DioException catch (error) {
      throw GoalException(_writeErrorMessage(error, "Progressni qo'shib bo'lmadi"));
    } catch (_) {
      throw const GoalException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
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

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(apiClientProvider));
});
