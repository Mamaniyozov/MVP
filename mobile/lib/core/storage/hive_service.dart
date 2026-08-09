import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/offline_cache.dart';

/// Hive-backed [OfflineCache]: persists API payloads on disk for offline-first
/// reads and queues optimistic mutations in the Hisob mobile client.
class HiveService implements OfflineCache {
  static const transactionsBoxName = OfflineCache.transactionsBoxName;
  static const categoriesBoxName = OfflineCache.categoriesBoxName;
  static const cardsBoxName = OfflineCache.cardsBoxName;
  static const budgetsBoxName = OfflineCache.budgetsBoxName;
  static const goalsBoxName = OfflineCache.goalsBoxName;
  static const offlineMutationsBoxName = OfflineCache.offlineMutationsBoxName;

  static const _boxNames = <String>[
    OfflineCache.transactionsBoxName,
    OfflineCache.categoriesBoxName,
    OfflineCache.cardsBoxName,
    OfflineCache.budgetsBoxName,
    OfflineCache.goalsBoxName,
    OfflineCache.offlineMutationsBoxName,
  ];

  bool _initialized = false;

  /// Initializes Hive for Flutter and opens all application cache boxes.
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait(_boxNames.map(Hive.openBox));
    _initialized = true;
  }

  @override
  Future<void> cacheData(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, jsonEncode(value));
  }

  @override
  dynamic getCachedData(String boxName, String key) {
    final raw = Hive.box(boxName).get(key);
    if (raw is! String) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearBox(String boxName) async {
    await Hive.box(boxName).clear();
  }

  @override
  Future<void> enqueueOfflineMutation(Map<String, dynamic> mutation) async {
    final box = Hive.box(OfflineCache.offlineMutationsBoxName);
    final id = MutationIdGenerator.next();
    final entry = Map<String, dynamic>.from(mutation)
      ..['mutation_id'] = id
      ..['created_at'] = DateTime.now().toIso8601String();
    await box.put(id, jsonEncode(entry));
  }

  @override
  List<Map<String, dynamic>> getPendingMutations() {
    final box = Hive.box(OfflineCache.offlineMutationsBoxName);
    final results = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! String) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) results.add(decoded);
      } catch (_) {
        // Corrupt entry — skip rather than blocking the whole queue.
      }
    }
    results.sort(
      (a, b) => '${a['mutation_id']}'.compareTo('${b['mutation_id']}'),
    );
    return results;
  }

  @override
  Future<void> removeOfflineMutation(String id) async {
    await Hive.box(OfflineCache.offlineMutationsBoxName).delete(id);
  }

  @override
  Future<void> clearOfflineQueue() async =>
      clearBox(OfflineCache.offlineMutationsBoxName);

  @override
  Future<void> clearAllCaches() async {
    await Future.wait(_boxNames.map(clearBox));
  }
}
