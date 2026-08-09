import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage-agnostic contract for the offline-first cache layer.
///
/// Production uses the Hive-backed implementation (`HiveService`); tests and
/// widget tests fall back to [InMemoryOfflineCache] so no platform channels
/// are required.
abstract class OfflineCache {
  static const transactionsBoxName = 'transactions_box';
  static const categoriesBoxName = 'categories_box';
  static const cardsBoxName = 'cards_box';
  static const budgetsBoxName = 'budgets_box';
  static const goalsBoxName = 'goals_box';
  static const offlineMutationsBoxName = 'offline_mutations_box';

  /// Caches a JSON-encodable [value] under [key] in [boxName].
  Future<void> cacheData(String boxName, String key, dynamic value);

  /// Returns the decoded payload for [key], or `null` when absent/corrupt.
  dynamic getCachedData(String boxName, String key);

  /// Clears every entry of a single box.
  Future<void> clearBox(String boxName);

  /// Queues a mutation performed while offline for later replay.
  Future<void> enqueueOfflineMutation(Map<String, dynamic> mutation);

  /// Pending mutations, oldest first.
  List<Map<String, dynamic>> getPendingMutations();

  /// Drops a mutation from the queue once it has been synced.
  Future<void> removeOfflineMutation(String id);

  /// Empties the mutation queue.
  Future<void> clearOfflineQueue();

  /// Wipes every cache — used on logout so a new user never sees stale data.
  Future<void> clearAllCaches();
}

/// Generates queue keys for offline mutations.
///
/// A bare `microsecondsSinceEpoch` is not enough: on platforms with a coarse
/// clock two mutations queued back-to-back get the same value and the second
/// silently overwrites the first. The sequence suffix guarantees uniqueness,
/// and both parts are zero-padded so lexicographic ordering matches insertion
/// order.
class MutationIdGenerator {
  static int _sequence = 0;

  static String next() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final seq = (_sequence = (_sequence + 1) % 1000000);
    return '${micros.toString().padLeft(19, '0')}-'
        '${seq.toString().padLeft(6, '0')}';
  }
}

/// Volatile [OfflineCache] used as the default binding. Keeps repositories
/// working (without persistence) in tests and before Hive has been initialised.
class InMemoryOfflineCache implements OfflineCache {
  final Map<String, Map<String, dynamic>> _boxes = {};

  Map<String, dynamic> _box(String name) => _boxes.putIfAbsent(name, () => {});

  /// Round-trips through JSON exactly like the Hive implementation so callers
  /// see the same decoded shapes in tests as in production.
  @override
  Future<void> cacheData(String boxName, String key, dynamic value) async {
    _box(boxName)[key] = jsonEncode(value);
  }

  @override
  dynamic getCachedData(String boxName, String key) {
    final raw = _box(boxName)[key];
    if (raw is! String) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearBox(String boxName) async => _box(boxName).clear();

  @override
  Future<void> enqueueOfflineMutation(Map<String, dynamic> mutation) async {
    final id = MutationIdGenerator.next();
    final entry = Map<String, dynamic>.from(mutation)
      ..['mutation_id'] = id
      ..['created_at'] = DateTime.now().toIso8601String();
    _box(OfflineCache.offlineMutationsBoxName)[id] = entry;
  }

  @override
  List<Map<String, dynamic>> getPendingMutations() {
    final entries = _box(OfflineCache.offlineMutationsBoxName)
        .values
        .whereType<Map<String, dynamic>>()
        .toList();
    entries.sort(
      (a, b) => '${a['mutation_id']}'.compareTo('${b['mutation_id']}'),
    );
    return entries;
  }

  @override
  Future<void> removeOfflineMutation(String id) async {
    _box(OfflineCache.offlineMutationsBoxName).remove(id);
  }

  @override
  Future<void> clearOfflineQueue() async =>
      clearBox(OfflineCache.offlineMutationsBoxName);

  @override
  Future<void> clearAllCaches() async => _boxes.clear();
}

/// Bound to [InMemoryOfflineCache] by default; `main()` overrides it with the
/// initialised Hive-backed service.
final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return InMemoryOfflineCache();
});
