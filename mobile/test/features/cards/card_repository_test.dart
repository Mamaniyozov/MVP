import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cards/data/card_exception.dart';
import 'package:mobile/features/cards/data/card_repository.dart';
import 'package:mobile/core/storage/offline_cache.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mock_dio.dart';

void main() {
  late MockDio dio;
  late CardRepository repository;

  late InMemoryOfflineCache cache;

  setUp(() {
    dio = MockDio();
    cache = InMemoryOfflineCache();
    repository = CardRepository(dio, cache);
  });

  group('list', () {
    test('parses the unpaginated card array, defaulting a missing last4 to empty', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/cards/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/cards/'),
          data: [
            {'id': 1, 'name': 'Humo', 'last4': '1234'},
            {'id': 2, 'name': 'Naqd', 'last4': null},
          ],
        ),
      );

      final cards = await repository.list();

      expect(cards, hasLength(2));
      expect(cards.first.displayName, 'Humo •••• 1234');
      expect(cards.last.last4, '');
      expect(cards.last.displayName, 'Naqd');
    });
  });

  group('create', () {
    test('sends name and last4', () async {
      when(
        () => dio.post<Map<String, dynamic>>('/api/v1/cards/', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/api/v1/cards/'), data: {}),
      );

      await repository.create(name: 'Uzcard', last4: '5678');

      final captured = verify(
        () => dio.post<Map<String, dynamic>>('/api/v1/cards/', data: captureAny(named: 'data')),
      ).captured.single as Map<String, dynamic>;

      expect(captured, {'name': 'Uzcard', 'last4': '5678'});
    });

    test('surfaces a DRF validation error message', () async {
      when(
        () => dio.post<Map<String, dynamic>>('/api/v1/cards/', data: any(named: 'data')),
      ).thenThrow(
        dioErrorWithResponse(
          path: '/api/v1/cards/',
          statusCode: 400,
          data: {
            'last4': ['Ensure this field has no more than 4 characters.'],
          },
        ),
      );

      await expectLater(
        repository.create(name: 'Uzcard', last4: '56789'),
        throwsA(
          isA<CardException>().having(
            (e) => e.message,
            'message',
            'Ensure this field has no more than 4 characters.',
          ),
        ),
      );
    });
  });

  group('update', () {
    test('patches the card at its id-scoped endpoint', () async {
      when(
        () => dio.patch<Map<String, dynamic>>('/api/v1/cards/3/', data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: '/api/v1/cards/3/'), data: {}),
      );

      await repository.update(id: 3, name: 'Yangi nom', last4: '0000');

      verify(
        () => dio.patch<Map<String, dynamic>>(
          '/api/v1/cards/3/',
          data: {'name': 'Yangi nom', 'last4': '0000'},
        ),
      ).called(1);
    });
  });

  group('delete', () {
    test('deletes the card at its id-scoped endpoint', () async {
      when(() => dio.delete<void>('/api/v1/cards/3/')).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/api/v1/cards/3/')),
      );

      await repository.delete(3);

      verify(() => dio.delete<void>('/api/v1/cards/3/')).called(1);
    });

    test('throws CardException with the delete fallback message', () async {
      when(() => dio.delete<void>('/api/v1/cards/3/')).thenThrow(
        dioErrorWithResponse(path: '/api/v1/cards/3/', statusCode: 500, data: {}),
      );

      await expectLater(
        repository.delete(3),
        throwsA(
          isA<CardException>()
              .having((e) => e.message, 'message', "Kartani o'chirib bo'lmadi"),
        ),
      );
    });
  });

  group('offline behaviour', () {
    Response<List<dynamic>> cardsResponse() => Response(
          requestOptions: RequestOptions(path: '/api/v1/cards/'),
          data: [
            {'id': 1, 'name': 'Humo', 'last4': '1234'},
          ],
        );

    test('serves cached cards when the server is unreachable', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/cards/'))
          .thenAnswer((_) async => cardsResponse());
      await repository.list();

      when(() => dio.get<List<dynamic>>('/api/v1/cards/'))
          .thenThrow(dioConnectionError(path: '/api/v1/cards/'));

      final cards = await repository.list();

      expect(cards, hasLength(1));
      expect(cards.single.name, 'Humo');
    });

    test('rethrows when offline with an empty cache', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/cards/'))
          .thenThrow(dioConnectionError(path: '/api/v1/cards/'));

      await expectLater(repository.list(), throwsA(isA<DioException>()));
    });
  });
}
