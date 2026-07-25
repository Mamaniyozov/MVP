import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/transactions/data/transaction_repository.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

/// Loads and holds the first page of the user's transactions.
///
/// MVP scope: page 1 only (20 most recent, newest first per backend
/// ordering). Pull-to-refresh re-fetches; further pagination (infinite
/// scroll) is a follow-up once the list screen is in daily use.
class TransactionListController extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final repository = ref.watch(transactionRepositoryProvider);
    final page = await repository.list();
    return page.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Transaction>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      final page = await repository.list();
      return page.items;
    });
  }
}

final transactionListControllerProvider =
    AsyncNotifierProvider<TransactionListController, List<Transaction>>(
  TransactionListController.new,
);
