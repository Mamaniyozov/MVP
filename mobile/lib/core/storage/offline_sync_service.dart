import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/storage/offline_cache.dart';

/// Replays mutations that were queued while the device was offline.
///
/// Each queued entry is `{method, path, body, mutation_id}`. Entries are
/// replayed oldest-first and removed only after the server accepts them, so a
/// failed replay stays in the queue for the next attempt.
class OfflineSyncService {
  OfflineSyncService(this._dio, this._cache);

  final Dio _dio;
  final OfflineCache _cache;

  bool _running = false;

  /// Returns the number of mutations successfully synced.
  Future<int> syncPending() async {
    if (_running) return 0;
    _running = true;
    var synced = 0;
    try {
      for (final mutation in _cache.getPendingMutations()) {
        final id = mutation['mutation_id'];
        final path = mutation['path'];
        if (id is! String || path is! String) {
          // Malformed entry — drop it so it cannot block the queue forever.
          if (id is String) await _cache.removeOfflineMutation(id);
          continue;
        }
        try {
          await _send(
            method: '${mutation['method'] ?? 'POST'}',
            path: path,
            body: mutation['body'],
          );
          await _cache.removeOfflineMutation(id);
          synced++;
        } on DioException catch (error) {
          if (error.response == null) {
            // Still offline — stop and retry the whole queue later.
            break;
          }
          // The server rejected it (validation, 404, ...). Retrying will never
          // succeed, so drop it instead of blocking later mutations.
          await _cache.removeOfflineMutation(id);
        }
      }
    } finally {
      _running = false;
    }
    return synced;
  }

  Future<void> _send({
    required String method,
    required String path,
    required dynamic body,
  }) {
    switch (method.toUpperCase()) {
      case 'PATCH':
        return _dio.patch<dynamic>(path, data: body);
      case 'PUT':
        return _dio.put<dynamic>(path, data: body);
      case 'DELETE':
        return _dio.delete<dynamic>(path, data: body);
      default:
        return _dio.post<dynamic>(path, data: body);
    }
  }
}

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    ref.watch(apiClientProvider),
    ref.watch(offlineCacheProvider),
  );
});
