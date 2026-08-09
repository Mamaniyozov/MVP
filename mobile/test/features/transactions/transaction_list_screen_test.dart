import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/categories/presentation/providers/category_providers.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/providers/transaction_list_controller.dart';
import 'package:mobile/features/transactions/presentation/screens/transaction_list_screen.dart';

Widget _pumpTransactionListScreen({
  required AsyncValue<List<Transaction>> transactions,
  AsyncValue<List<Category>>? categories,
}) {
  return ProviderScope(
    overrides: [
      transactionListControllerProvider.overrideWith(() => _FakeTransactionListController(transactions)),
      if (categories != null)
        allCategoriesProvider.overrideWith((ref) async => categories.value ?? []),
    ],
    child: const MaterialApp(
      home: TransactionListScreen(),
    ),
  );
}

/// Seeds the screen from a fixed [AsyncValue]. The value has to come out of
/// `build()` — assigning `state` in the constructor is overwritten as soon as
/// the notifier builds, which would then hit the real repository.
class _FakeTransactionListController extends TransactionListController {
  _FakeTransactionListController(this._initial);

  final AsyncValue<List<Transaction>> _initial;

  @override
  Future<List<Transaction>> build() => _initial.when(
        data: (transactions) async => transactions,
        error: (error, stackTrace) =>
            Future<List<Transaction>>.error(error, stackTrace),
        loading: () => Completer<List<Transaction>>().future,
      );
}

void main() {
  testWidgets('renders empty view when transaction list is empty', (tester) async {
    await tester.pumpWidget(_pumpTransactionListScreen(
      transactions: const AsyncData([]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tranzaksiyalar'), findsOneWidget);
    expect(find.text("Hali tranzaksiya yo'q"), findsOneWidget);
  });

  testWidgets('renders transaction list items', (tester) async {
    final transactions = [
      Transaction(
        id: 1,
        amount: 50000,
        type: CategoryType.expense,
        categoryId: 1,
        cardId: 1,
        goalId: null,
        date: DateTime(2026, 7, 31),
        note: 'Tushlik',
      ),
    ];
    final categories = [
      const Category(id: 1, name: 'Oziq-ovqat', type: CategoryType.expense, icon: '', isDefault: true),
    ];

    await tester.pumpWidget(_pumpTransactionListScreen(
      transactions: AsyncData(transactions),
      categories: AsyncData(categories),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tranzaksiyalar'), findsOneWidget);
    expect(find.text('Oziq-ovqat'), findsOneWidget);
    expect(find.textContaining('Tushlik'), findsOneWidget);
  });
}
