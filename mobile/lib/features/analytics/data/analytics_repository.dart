import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/analytics/data/analytics_exception.dart';
import 'package:mobile/features/analytics/domain/category_breakdown_entry.dart';
import 'package:mobile/features/analytics/domain/monthly_report.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._dio);

  final Dio _dio;

  Future<List<CategoryBreakdownEntry>> categoryBreakdown({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/analytics/category-breakdown/',
        queryParameters: {'month': month, 'year': year},
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(CategoryBreakdownEntry.fromJson)
          .toList();
    } on DioException catch (error) {
      throw AnalyticsException(_networkErrorMessage(error));
    } catch (_) {
      throw const AnalyticsException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<MonthlyReport> monthlyReport({required int month, required int year}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/analytics/monthly-report/',
        queryParameters: {'month': month, 'year': year},
      );
      return MonthlyReport.fromJson(response.data!);
    } on DioException catch (error) {
      throw AnalyticsException(_networkErrorMessage(error));
    } catch (_) {
      throw const AnalyticsException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  String _networkErrorMessage(DioException error) {
    if (error.response != null) {
      return "Ma'lumotlarni yuklab bo'lmadi";
    }
    return "Serverga ulanib bo'lmadi. Internet aloqasini tekshiring";
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(apiClientProvider));
});
