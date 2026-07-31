import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/goals/data/goal_exception.dart';
import 'package:mobile/features/goals/data/goal_repository.dart';
import 'package:mobile/features/goals/domain/goal.dart';
import 'package:mobile/features/goals/presentation/providers/goal_list_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository repository;
  late ProviderContainer container;

  const goal = Goal(
    id: 1,
    name: 'Ta\'til',
    targetAmount: 1000,
    currentAmount: 250,
    deadline: null,
    progressPercent: 25,
  );

  setUp(() {
    repository = MockGoalRepository();
    container = ProviderContainer(
      overrides: [goalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('build loads the goal list from the repository', () async {
    when(() => repository.list()).thenAnswer((_) async => [goal]);

    final result = await container.read(goalListControllerProvider.future);

    expect(result, [goal]);
    verify(() => repository.list()).called(1);
  });

  test('build surfaces a GoalException as AsyncError', () async {
    when(() => repository.list()).thenThrow(const GoalException("Ma'lumotlarni yuklab bo'lmadi"));

    await expectLater(
      container.read(goalListControllerProvider.future),
      throwsA(isA<GoalException>()),
    );
  });

  test('refresh re-fetches and replaces the state with fresh data', () async {
    when(() => repository.list()).thenAnswer((_) async => [goal]);
    await container.read(goalListControllerProvider.future);

    final updatedGoal = Goal(
      id: 1,
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: 500,
      deadline: null,
      progressPercent: 50,
    );
    when(() => repository.list()).thenAnswer((_) async => [updatedGoal]);

    await container.read(goalListControllerProvider.notifier).refresh();

    final state = container.read(goalListControllerProvider);
    expect(state.value, [updatedGoal]);
    verify(() => repository.list()).called(2);
  });

  test('refresh keeps the previous data visible while reloading', () async {
    when(() => repository.list()).thenAnswer((_) async => [goal]);
    await container.read(goalListControllerProvider.future);

    when(() => repository.list()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return [goal];
    });

    final refreshFuture = container.read(goalListControllerProvider.notifier).refresh();
    final duringRefresh = container.read(goalListControllerProvider);

    expect(duringRefresh.isLoading, isTrue);
    expect(duringRefresh.value, [goal]);

    await refreshFuture;
  });
}
