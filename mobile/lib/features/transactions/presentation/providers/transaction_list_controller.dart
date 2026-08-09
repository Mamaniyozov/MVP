import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/offline_sync_service.dart';
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
    return _loadAndDrainQueue(repository);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Transaction>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => _loadAndDrainQueue(ref.read(transactionRepositoryProvider)),
    );
  }

  /// Fetches page 1 and, because a successful fetch proves the device is
  /// online, replays anything queued while it was offline — re-fetching once
  /// more when the replay actually pushed something new to the server.
  Future<List<Transaction>> _loadAndDrainQueue(
    TransactionRepository repository,
  ) async {
    final page = await repository.list();
    final synced = await ref.read(offlineSyncServiceProvider).syncPending();
    if (synced == 0) return page.items;
    return (await repository.list()).items;
  }
}

final transactionListControllerProvider =
    AsyncNotifierProvider<TransactionListController, List<Transaction>>(
  TransactionListController.new,
);
