import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/category_breakdown_entry.dart';
import 'package:mobile/features/analytics/presentation/providers/category_breakdown_controller.dart';
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

    // build() always uses DateTime.now(); stub every month/year combination
    // requested during a test with the same trivially-empty response.
    when(
      () => repository.categoryBreakdown(
        month: any(named: 'month'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) async => const <CategoryBreakdownEntry>[]);
  });

  test('build loads the current month', () async {
    final now = DateTime.now();

    final state = await container.read(categoryBreakdownControllerProvider.future);

    expect(state.month, now.month);
    expect(state.year, now.year);
  });

  test('previousMonth steps back a month within the same year', () async {
    await container.read(categoryBreakdownControllerProvider.future);
    final notifier = container.read(categoryBreakdownControllerProvider.notifier);
    notifier.state = const AsyncData(
      CategoryBreakdownState(year: 2026, month: 7, entries: []),
    );

    await notifier.previousMonth();

    final state = container.read(categoryBreakdownControllerProvider).value!;
    expect(state.year, 2026);
    expect(state.month, 6);
    verify(() => repository.categoryBreakdown(month: 6, year: 2026)).called(1);
  });

  test('previousMonth wraps from January into December of the prior year', () async {
    await container.read(categoryBreakdownControllerProvider.future);
    final notifier = container.read(categoryBreakdownControllerProvider.notifier);
    notifier.state = const AsyncData(
      CategoryBreakdownState(year: 2026, month: 1, entries: []),
    );

    await notifier.previousMonth();

    final state = container.read(categoryBreakdownControllerProvider).value!;
    expect(state.year, 2025);
    expect(state.month, 12);
    verify(() => repository.categoryBreakdown(month: 12, year: 2025)).called(1);
  });

  test('nextMonth steps forward a month within the same year', () async {
    await container.read(categoryBreakdownControllerProvider.future);
    final notifier = container.read(categoryBreakdownControllerProvider.notifier);
    notifier.state = const AsyncData(
      CategoryBreakdownState(year: 2026, month: 7, entries: []),
    );

    await notifier.nextMonth();

    final state = container.read(categoryBreakdownControllerProvider).value!;
    expect(state.year, 2026);
    expect(state.month, 8);
  });

  test('nextMonth wraps from December into January of the next year', () async {
    await container.read(categoryBreakdownControllerProvider.future);
    final notifier = container.read(categoryBreakdownControllerProvider.notifier);
    notifier.state = const AsyncData(
      CategoryBreakdownState(year: 2025, month: 12, entries: []),
    );

    await notifier.nextMonth();

    final state = container.read(categoryBreakdownControllerProvider).value!;
    expect(state.year, 2026);
    expect(state.month, 1);
    verify(() => repository.categoryBreakdown(month: 1, year: 2026)).called(1);
  });

  test('previousMonth is a no-op while there is no loaded state yet', () async {
    // A fresh container whose build() hasn't resolved: state is AsyncLoading
    // with no previous value, so valueOrNull is null and _goTo must not run.
    // build() itself makes exactly one call; previousMonth() called before
    // that resolves must not add a second one.
    final freshContainer = ProviderContainer(
      overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(freshContainer.dispose);

    final notifier = freshContainer.read(categoryBreakdownControllerProvider.notifier);
    await notifier.previousMonth();

    verify(
      () => repository.categoryBreakdown(month: any(named: 'month'), year: any(named: 'year')),
    ).called(1);
  });
}
