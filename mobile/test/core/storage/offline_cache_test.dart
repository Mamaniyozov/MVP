import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/offline_cache.dart';

void main() {
  late InMemoryOfflineCache cache;

  setUp(() {
    cache = InMemoryOfflineCache();
  });

  group('cacheData / getCachedData', () {
    test('round-trips a JSON map through the cache', () async {
      await cache.cacheData(OfflineCache.transactionsBoxName, 'page_1', {
        'count': 2,
        'results': [
          {'id': 1, 'amount': '10.00'},
        ],
      });

      final cached =
          cache.getCachedData(OfflineCache.transactionsBoxName, 'page_1');

      expect(cached, isA<Map<String, dynamic>>());
      expect(cached['count'], 2);
      expect(cached['results'], hasLength(1));
    });

    test('returns null for an unknown key', () {
      expect(cache.getCachedData(OfflineCache.cardsBoxName, 'missing'), isNull);
    });

    test('keeps boxes isolated from one another', () async {
      await cache.cacheData(OfflineCache.cardsBoxName, 'all', [1, 2]);

      expect(cache.getCachedData(OfflineCache.categoriesBoxName, 'all'), isNull);
      expect(cache.getCachedData(OfflineCache.cardsBoxName, 'all'), [1, 2]);
    });

    test('clearBox empties only the requested box', () async {
      await cache.cacheData(OfflineCache.cardsBoxName, 'all', [1]);
      await cache.cacheData(OfflineCache.categoriesBoxName, 'all', [2]);

      await cache.clearBox(OfflineCache.cardsBoxName);

      expect(cache.getCachedData(OfflineCache.cardsBoxName, 'all'), isNull);
      expect(cache.getCachedData(OfflineCache.categoriesBoxName, 'all'), [2]);
    });

    test('clearAllCaches wipes every box — required on logout', () async {
      await cache.cacheData(OfflineCache.cardsBoxName, 'all', [1]);
      await cache.cacheData(OfflineCache.goalsBoxName, 'all', [2]);
      await cache.enqueueOfflineMutation({'path': '/api/v1/transactions/'});

      await cache.clearAllCaches();

      expect(cache.getCachedData(OfflineCache.cardsBoxName, 'all'), isNull);
      expect(cache.getCachedData(OfflineCache.goalsBoxName, 'all'), isNull);
      expect(cache.getPendingMutations(), isEmpty);
    });
  });

  group('offline mutation queue', () {
    test('stamps queued mutations with an id and timestamp', () async {
      await cache.enqueueOfflineMutation({
        'method': 'POST',
        'path': '/api/v1/transactions/',
        'body': {'amount': '10.00'},
      });

      final pending = cache.getPendingMutations();

      expect(pending, hasLength(1));
      expect(pending.single['mutation_id'], isA<String>());
      expect(pending.single['created_at'], isA<String>());
      expect(pending.single['path'], '/api/v1/transactions/');
    });

    test('returns pending mutations oldest first', () async {
      await cache.enqueueOfflineMutation({'path': '/first/'});
      await cache.enqueueOfflineMutation({'path': '/second/'});

      final paths =
          cache.getPendingMutations().map((m) => m['path']).toList();

      expect(paths, ['/first/', '/second/']);
    });

    test('removeOfflineMutation drops only the synced entry', () async {
      await cache.enqueueOfflineMutation({'path': '/first/'});
      await cache.enqueueOfflineMutation({'path': '/second/'});
      final firstId = cache.getPendingMutations().first['mutation_id'] as String;

      await cache.removeOfflineMutation(firstId);

      final remaining = cache.getPendingMutations();
      expect(remaining, hasLength(1));
      expect(remaining.single['path'], '/second/');
    });

    test('clearOfflineQueue leaves data caches intact', () async {
      await cache.cacheData(OfflineCache.cardsBoxName, 'all', [1]);
      await cache.enqueueOfflineMutation({'path': '/first/'});

      await cache.clearOfflineQueue();

      expect(cache.getPendingMutations(), isEmpty);
      expect(cache.getCachedData(OfflineCache.cardsBoxName, 'all'), [1]);
    });
  });
}
