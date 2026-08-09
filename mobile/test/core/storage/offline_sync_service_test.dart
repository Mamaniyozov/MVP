import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/offline_cache.dart';
import 'package:mobile/core/storage/offline_sync_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mock_dio.dart';

void main() {
  late MockDio dio;
  late InMemoryOfflineCache cache;
  late OfflineSyncService service;

  const path = '/api/v1/transactions/';

  setUp(() {
    dio = MockDio();
    cache = InMemoryOfflineCache();
    service = OfflineSyncService(dio, cache);
    registerFallbackValue(<String, dynamic>{});
  });

  Future<void> queueCreate({String note = 'Tushlik'}) {
    return cache.enqueueOfflineMutation({
      'method': 'POST',
      'path': path,
      'body': {'amount': '10.00', 'note': note},
    });
  }

  void stubPostSuccess() {
    when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: 201,
      ),
    );
  }

  test('replays queued mutations and clears them on success', () async {
    await queueCreate(note: 'first');
    await queueCreate(note: 'second');
    stubPostSuccess();

    final synced = await service.syncPending();

    expect(synced, 2);
    expect(cache.getPendingMutations(), isEmpty);
    verify(() => dio.post<dynamic>(path, data: any(named: 'data'))).called(2);
  });

  test('keeps the mutation queued when the device is still offline', () async {
    await queueCreate();
    when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
        .thenThrow(dioConnectionError(path: path));

    final synced = await service.syncPending();

    expect(synced, 0);
    expect(cache.getPendingMutations(), hasLength(1));
  });

  test('drops a mutation the server rejects so it cannot block the queue', () async {
    await queueCreate();
    when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenThrow(
      dioErrorWithResponse(
        path: path,
        statusCode: 400,
        data: {'amount': ['Noto\'g\'ri qiymat']},
      ),
    );

    final synced = await service.syncPending();

    expect(synced, 0);
    expect(cache.getPendingMutations(), isEmpty);
  });

  test('does nothing when the queue is empty', () async {
    expect(await service.syncPending(), 0);
    verifyNever(() => dio.post<dynamic>(any(), data: any(named: 'data')));
  });
}
