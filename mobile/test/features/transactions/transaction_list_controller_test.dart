import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/transactions/data/transaction_repository.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_page.dart';
import 'package:mobile/features/transactions/presentation/providers/transaction_list_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;
  late ProviderContainer container;

  final transaction = Transaction(
    id: 1,
    categoryId: 2,
    cardId: null,
    goalId: null,
    amount: 5000,
    type: CategoryType.expense,
    date: DateTime(2026, 7, 1),
    note: '',
  );

  setUp(() {
    repository = MockTransactionRepository();
    container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('build unwraps the first page into a flat transaction list', () async {
    when(() => repository.list()).thenAnswer(
      (_) async => TransactionPage(items: [transaction], hasNext: true),
    );

    final result = await container.read(transactionListControllerProvider.future);

    expect(result, [transaction]);
    verify(() => repository.list()).called(1);
  });

  test('refresh re-fetches page 1 and replaces the state', () async {
    when(() => repository.list()).thenAnswer(
      (_) async => TransactionPage(items: [transaction], hasNext: false),
    );
    await container.read(transactionListControllerProvider.future);

    final newer = Transaction(
      id: 2,
      categoryId: 2,
      cardId: null,
      goalId: null,
      amount: 9000,
      type: CategoryType.income,
      date: DateTime(2026, 7, 2),
      note: '',
    );
    when(() => repository.list()).thenAnswer(
      (_) async => TransactionPage(items: [newer, transaction], hasNext: false),
    );

    await container.read(transactionListControllerProvider.notifier).refresh();

    final state = container.read(transactionListControllerProvider);
    expect(state.value, [newer, transaction]);
  });
}
