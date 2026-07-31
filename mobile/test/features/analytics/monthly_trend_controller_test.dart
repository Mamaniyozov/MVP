import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_exception.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/monthly_trend_entry.dart';
import 'package:mobile/features/analytics/presentation/providers/monthly_trend_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late MockAnalyticsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAnalyticsRepository();
    container = ProviderContainer(
      overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('requests a fixed rolling window of 6 months', () async {
    when(() => repository.monthlyTrend(months: 6)).thenAnswer(
      (_) async => const [
        MonthlyTrendEntry(month: '2026-07', income: 5000000, expense: 3000000),
      ],
    );

    final entries = await container.read(monthlyTrendControllerProvider.future);

    expect(entries, hasLength(1));
    verify(() => repository.monthlyTrend(months: 6)).called(1);
  });

  test('a repository failure surfaces as an AsyncError with the AnalyticsException', () async {
    when(() => repository.monthlyTrend(months: 6))
        .thenThrow(const AnalyticsException("Ma'lumotlarni yuklab bo'lmadi"));

    await expectLater(
      container.read(monthlyTrendControllerProvider.future),
      throwsA(isA<AnalyticsException>()),
    );
  });
}
