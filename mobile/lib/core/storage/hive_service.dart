import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Central storage service managing Hive boxes for offline-first caching
/// and optimistic mutation queueing in the Hisob mobile client.
class HiveService {
  static const transactionsBoxName = 'transactions_box';
  static const categoriesBoxName = 'categories_box';
  static const cardsBoxName = 'cards_box';
  static const budgetsBoxName = 'budgets_box';
  static const goalsBoxName = 'goals_box';
  static const offlineMutationsBoxName = 'offline_mutations_box';

  bool _initialized = false;

  /// Initializes Hive for Flutter and opens all application cache boxes.
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    
    await Future.wait([
      Hive.openBox(transactionsBoxName),
      Hive.openBox(categoriesBoxName),
      Hive.openBox(cardsBoxName),
      Hive.openBox(budgetsBoxName),
      Hive.openBox(goalsBoxName),
      Hive.openBox(offlineMutationsBoxName),
    ]);
    
    _initialized = true;
  }

  /// Caches a JSON-encodable payload under [key] in the specified [boxName].
  Future<void> cacheData(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    final jsonString = jsonEncode(value);
    await box.put(key, jsonString);
  }

  /// Retrieves cached data for [key] from [boxName], decoding JSON string payload.
  dynamic getCachedData(String boxName, String key) {
    final box = Hive.box(boxName);
    final raw = box.get(key);
    if (raw == null || raw is! String) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Clears all entries in a specific cache box.
  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  /// Enqueues a pending offline mutation (e.g. POST/PUT request payload)
  /// to be synced when internet connectivity is restored.
  Future<void> enqueueOfflineMutation(Map<String, dynamic> mutation) async {
    final box = Hive.box(offlineMutationsBoxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    mutation['mutation_id'] = id;
    mutation['created_at'] = DateTime.now().toIso8601String();
    await box.put(id, jsonEncode(mutation));
  }

  /// Retrieves all pending offline mutations sorted by creation timestamp.
  List<Map<String, dynamic>> getPendingMutations() {
    final box = Hive.box(offlineMutationsBoxName);
    final results = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final raw = box.get(key);
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            results.add(decoded);
          }
        } catch (_) {}
      }
    }
    results.sort((a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''));
    return results;
  }

  /// Removes a synced mutation from the offline queue by its [id].
  Future<void> removeOfflineMutation(String id) async {
    final box = Hive.box(offlineMutationsBoxName);
    await box.delete(id);
  }

  /// Clears all pending mutations from the queue.
  Future<void> clearOfflineQueue() async {
    await clearBox(offlineMutationsBoxName);
  }

  /// Clears all application caches (e.g. on logout).
  Future<void> clearAllCaches() async {
    await Future.wait([
      clearBox(transactionsBoxName),
      clearBox(categoriesBoxName),
      clearBox(cardsBoxName),
      clearBox(budgetsBoxName),
      clearBox(goalsBoxName),
      clearBox(offlineMutationsBoxName),
    ]);
  }
}

/// Riverpod provider delivering the single [HiveService] instance across the app.
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});
