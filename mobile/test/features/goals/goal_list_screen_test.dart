import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/goals/domain/goal.dart';
import 'package:mobile/features/goals/presentation/providers/goal_list_controller.dart';
import 'package:mobile/features/goals/presentation/screens/goal_list_screen.dart';

Widget _pumpGoalListScreen(AsyncValue<List<Goal>> goals) {
  return ProviderScope(
    overrides: [
      goalListControllerProvider.overrideWith(() => _FakeGoalListController(goals)),
    ],
    child: const MaterialApp(
      home: GoalListScreen(),
    ),
  );
}

/// Seeds the screen from a fixed [AsyncValue]. The value has to come out of
/// `build()` — assigning `state` in the constructor is overwritten as soon as
/// the notifier builds, which would then hit the real repository.
class _FakeGoalListController extends GoalListController {
  _FakeGoalListController(this._initial);

  final AsyncValue<List<Goal>> _initial;

  @override
  Future<List<Goal>> build() => _initial.when(
        data: (goals) async => goals,
        error: (error, stackTrace) => Future<List<Goal>>.error(error, stackTrace),
        loading: () => Completer<List<Goal>>().future,
      );
}

void main() {
  testWidgets('renders empty view when goals list is empty', (tester) async {
    await tester.pumpWidget(_pumpGoalListScreen(const AsyncData([])));
    await tester.pumpAndSettle();

    expect(find.text('Maqsadlar'), findsOneWidget);
    expect(find.text("Hali maqsad yo'q"), findsOneWidget);
  });

  testWidgets('renders goal card with progress percent and title', (tester) async {
    final goals = [
      Goal(
        id: 1,
        name: 'Avtomobil jamg\'armasi',
        targetAmount: 10000000,
        currentAmount: 2500000,
        progressPercent: 25,
        deadline: DateTime(2026, 12, 31),
      ),
    ];

    await tester.pumpWidget(_pumpGoalListScreen(AsyncData(goals)));
    await tester.pumpAndSettle();

    expect(find.text('Maqsadlar'), findsOneWidget);
    expect(find.text('Avtomobil jamg\'armasi'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('Progress qo\'shish'), findsOneWidget);
  });
}
