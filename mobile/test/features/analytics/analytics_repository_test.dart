import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_exception.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mock_dio.dart';

void main() {
  late MockDio dio;
  late AnalyticsRepository repository;

  setUp(() {
    dio = MockDio();
    repository = AnalyticsRepository(dio);
  });

  group('categoryBreakdown', () {
    const path = '/api/v1/analytics/category-breakdown/';

    test('sends month/year query params and parses entries', () async {
      when(
        () => dio.get<List<dynamic>>(path, queryParameters: {'month': 7, 'year': 2026}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: [
            {'category': 'Oziq-ovqat', 'total': '450000.00', 'percent': '60.00'},
          ],
        ),
      );

      final entries = await repository.categoryBreakdown(month: 7, year: 2026);

      expect(entries, hasLength(1));
      expect(entries.single.category, 'Oziq-ovqat');
      expect(entries.single.total, 450000.0);
      expect(entries.single.percent, 60.0);
    });

    test('throws AnalyticsException with a connection message on network failure', () async {
      when(
        () => dio.get<List<dynamic>>(path, queryParameters: any(named: 'queryParameters')),
      ).thenThrow(dioConnectionError(path: path));

      await expectLater(
        repository.categoryBreakdown(month: 1, year: 2026),
        throwsA(
          isA<AnalyticsException>().having(
            (e) => e.message,
            'message',
            "Serverga ulanib bo'lmadi. Internet aloqasini tekshiring",
          ),
        ),
      );
    });
  });

  group('monthlyTrend', () {
    const path = '/api/v1/analytics/monthly-trend/';

    test('defaults to a 6-month window and parses entries in order', () async {
      when(
        () => dio.get<List<dynamic>>(path, queryParameters: {'months': 6}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: [
            {'month': '2026-06', 'income': '5000000.00', 'expense': '3000000.00'},
            {'month': '2026-07', 'income': '5200000.00', 'expense': '3100000.00'},
          ],
        ),
      );

      final entries = await repository.monthlyTrend();

      expect(entries, hasLength(2));
      expect(entries.first.month, '2026-06');
      expect(entries.last.income, 5200000.0);
    });

    test('a server error response yields the generic AnalyticsException message', () async {
      when(
        () => dio.get<List<dynamic>>(path, queryParameters: any(named: 'queryParameters')),
      ).thenThrow(dioErrorWithResponse(path: path, statusCode: 500));

      await expectLater(
        repository.monthlyTrend(),
        throwsA(
          isA<AnalyticsException>()
              .having((e) => e.message, 'message', "Ma'lumotlarni yuklab bo'lmadi"),
        ),
      );
    });
  });

  group('monthlyReport', () {
    const path = '/api/v1/analytics/monthly-report/';

    test('parses a full report with previous month and insights', () async {
      when(
        () => dio.get<Map<String, dynamic>>(path, queryParameters: {'month': 7, 'year': 2026}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: {
            'current_month': {'income': '5000000.00', 'expense': '3000000.00', 'savings': '2000000.00'},
            'previous_month': {'income': '4800000.00', 'expense': '3200000.00', 'savings': '1600000.00'},
            'change_percent': {'income': '4.17', 'expense': '-6.25', 'savings': '25.00'},
            'top_category_increase': {'name': 'Transport', 'percent': '30.00'},
            'insights': ['Bu oy xarajatlaringiz kamaydi'],
          },
        ),
      );

      final report = await repository.monthlyReport(month: 7, year: 2026);

      expect(report.currentMonth.income, 5000000.0);
      expect(report.previousMonth?.savings, 1600000.0);
      expect(report.changePercent?.expense, -6.25);
      expect(report.topCategoryIncrease?.name, 'Transport');
      expect(report.insights, ['Bu oy xarajatlaringiz kamaydi']);
    });

    test('parses a first-month report with no history as all-null optionals', () async {
      when(
        () => dio.get<Map<String, dynamic>>(path, queryParameters: {'month': 1, 'year': 2026}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: {
            'current_month': {'income': '0.00', 'expense': '0.00', 'savings': '0.00'},
            'previous_month': null,
            'change_percent': null,
            'top_category_increase': null,
            'insights': <String>[],
          },
        ),
      );

      final report = await repository.monthlyReport(month: 1, year: 2026);

      expect(report.previousMonth, isNull);
      expect(report.changePercent, isNull);
      expect(report.topCategoryIncrease, isNull);
      expect(report.insights, isEmpty);
    });
  });
}
