import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/monthly_report.dart';
import 'package:mobile/features/analytics/presentation/providers/monthly_report_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late MockAnalyticsRepository repository;
  late ProviderContainer container;

  const sampleReport = MonthlyReport(
    currentMonth: MonthTotals(income: 1000, expense: 500, savings: 500),
    previousMonth: MonthTotals(income: 1000, expense: 500, savings: 500),
    changePercent: ChangePercent(income: 0, expense: 0, savings: 0),
    topCategoryIncrease: TopCategoryIncrease(name: 'Transport', percent: 12),
    insights: ['Yaxshi saqlandi'],
  );

  setUp(() {
    repository = MockAnalyticsRepository();
    container = ProviderContainer(
      overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    when(
      () => repository.monthlyReport(
        month: any(named: 'month'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) async => sampleReport);
  });

  test('build loads current month report', () async {
    final now = DateTime.now();

    final state = await container.read(monthlyReportControllerProvider.future);

    expect(state.month, now.month);
    expect(state.year, now.year);
    expect(state.report, equals(sampleReport));
  });

  test('previousMonth steps back one month within same year', () async {
    await container.read(monthlyReportControllerProvider.future);
    final notifier = container.read(monthlyReportControllerProvider.notifier);
    notifier.state = const AsyncData(
      MonthlyReportState(year: 2020, month: 7, report: sampleReport),
    );

    await notifier.previousMonth();

    final state = container.read(monthlyReportControllerProvider).value!;
    expect(state.year, 2020);
    expect(state.month, 6);
    verify(() => repository.monthlyReport(month: 6, year: 2020)).called(1);
  });

  test('previousMonth wraps from January into December of prior year', () async {
    await container.read(monthlyReportControllerProvider.future);
    final notifier = container.read(monthlyReportControllerProvider.notifier);
    notifier.state = const AsyncData(
      MonthlyReportState(year: 2020, month: 1, report: sampleReport),
    );

    await notifier.previousMonth();

    final state = container.read(monthlyReportControllerProvider).value!;
    expect(state.year, 2019);
    expect(state.month, 12);
    verify(() => repository.monthlyReport(month: 12, year: 2019)).called(1);
  });

  test('nextMonth steps forward one month within same year', () async {
    await container.read(monthlyReportControllerProvider.future);
    final notifier = container.read(monthlyReportControllerProvider.notifier);
    notifier.state = const AsyncData(
      MonthlyReportState(year: 2020, month: 7, report: sampleReport),
    );

    await notifier.nextMonth();

    final state = container.read(monthlyReportControllerProvider).value!;
    expect(state.year, 2020);
    expect(state.month, 8);
    verify(() => repository.monthlyReport(month: 8, year: 2020)).called(1);
  });
}
