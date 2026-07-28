import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/goals/data/goal_repository.dart';
import 'package:mobile/features/goals/domain/goal.dart';

/// Loads and holds the user's savings goals.
class GoalListController extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    final repository = ref.watch(goalRepositoryProvider);
    return repository.list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Goal>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => ref.read(goalRepositoryProvider).list());
  }
}

final goalListControllerProvider = AsyncNotifierProvider<GoalListController, List<Goal>>(
  GoalListController.new,
);
