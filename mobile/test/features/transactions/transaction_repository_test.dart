import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/transactions/data/transaction_exception.dart';
import 'package:mobile/features/transactions/data/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mock_dio.dart';

void main() {
  late MockDio dio;
  late TransactionRepository repository;

  const path = '/api/v1/transactions/';

  setUp(() {
    dio = MockDio();
    repository = TransactionRepository(dio);
  });

  group('list', () {
    test('parses a paginated page and detects a next page', () async {
      when(
        () => dio.get<Map<String, dynamic>>(path, queryParameters: {'page': 1}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: {
            'next': 'http://api/transactions/?page=2',
            'results': [
              {
                'id': 10,
                'category': 3,
                'card': 1,
                'goal': null,
                'amount': '25000.00',
                'type': 'expense',
                'date': '2026-07-29',
                'note': 'Kofe',
              },
            ],
          },
        ),
      );

      final page = await repository.list();

      expect(page.hasNext, isTrue);
      expect(page.items, hasLength(1));
      expect(page.items.single.type, CategoryType.expense);
      expect(page.items.single.cardId, 1);
      expect(page.items.single.goalId, isNull);
    });

    test('a null next field means there is no further page', () async {
      when(
        () => dio.get<Map<String, dynamic>>(path, queryParameters: {'page': 2}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: {'next': null, 'results': <dynamic>[]},
        ),
      );

      final page = await repository.list(page: 2);

      expect(page.hasNext, isFalse);
      expect(page.items, isEmpty);
    });

    test('throws TransactionException on a network failure', () async {
      when(
        () => dio.get<Map<String, dynamic>>(path, queryParameters: any(named: 'queryParameters')),
      ).thenThrow(dioConnectionError(path: path));

      await expectLater(
        repository.list(),
        throwsA(isA<TransactionException>()),
      );
    });
  });

  group('create', () {
    test('omits card/goal when absent and formats amount and date', () async {
      when(
        () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: path), data: {}),
      );

      await repository.create(
        categoryId: 5,
        cardId: null,
        goalId: null,
        amount: 12345.6,
        type: CategoryType.income,
        date: DateTime(2026, 1, 9),
        note: 'Ish haqi',
      );

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(path, data: captureAny(named: 'data')),
      ).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('card'), isFalse);
      expect(captured.containsKey('goal'), isFalse);
      expect(captured['amount'], '12345.60');
      expect(captured['type'], 'income');
      expect(captured['date'], '2026-01-09');
    });

    test('includes card and goal ids when both are given', () async {
      when(
        () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: path), data: {}),
      );

      await repository.create(
        categoryId: 5,
        cardId: 2,
        goalId: 9,
        amount: 100,
        type: CategoryType.expense,
        date: DateTime(2026, 1, 9),
        note: '',
      );

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(path, data: captureAny(named: 'data')),
      ).captured.single as Map<String, dynamic>;

      expect(captured['card'], 2);
      expect(captured['goal'], 9);
    });

    test('surfaces the first DRF validation error message on create', () async {
      when(
        () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
      ).thenThrow(
        dioErrorWithResponse(
          path: path,
          statusCode: 400,
          data: {
            'goal': ['Goal can only be attached to an expense transaction.'],
          },
        ),
      );

      await expectLater(
        repository.create(
          categoryId: 5,
          cardId: null,
          goalId: 9,
          amount: 100,
          type: CategoryType.income,
          date: DateTime(2026, 1, 9),
          note: '',
        ),
        throwsA(
          isA<TransactionException>().having(
            (e) => e.message,
            'message',
            'Goal can only be attached to an expense transaction.',
          ),
        ),
      );
    });

    test('falls back to the generic create-error message with no field errors', () async {
      when(
        () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
      ).thenThrow(dioErrorWithResponse(path: path, statusCode: 500, data: {}));

      await expectLater(
        repository.create(
          categoryId: 5,
          cardId: null,
          goalId: null,
          amount: 100,
          type: CategoryType.expense,
          date: DateTime(2026, 1, 9),
          note: '',
        ),
        throwsA(
          isA<TransactionException>()
              .having((e) => e.message, 'message', "Tranzaksiyani saqlab bo'lmadi"),
        ),
      );
    });
  });
}
