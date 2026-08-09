import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/data/category_exception.dart';
import 'package:mobile/features/categories/data/category_repository.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/core/storage/offline_cache.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mock_dio.dart';

void main() {
  late MockDio dio;
  late CategoryRepository repository;

  const path = '/api/v1/categories/';

  late InMemoryOfflineCache cache;

  setUp(() {
    dio = MockDio();
    cache = InMemoryOfflineCache();
    repository = CategoryRepository(dio, cache);
  });

  group('list', () {
    test('with no type filter sends no query parameters', () async {
      when(() => dio.get<List<dynamic>>(path, queryParameters: null)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: [
            {'id': 1, 'name': 'Transport', 'type': 'expense', 'icon': '', 'is_default': true},
          ],
        ),
      );

      final categories = await repository.list();

      expect(categories.single.isDefault, isTrue);
      expect(categories.single.type, CategoryType.expense);
    });

    test('filters by type when given', () async {
      when(
        () => dio.get<List<dynamic>>(path, queryParameters: {'type': 'income'}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: path),
          data: [
            {'id': 2, 'name': 'Maosh', 'type': 'income', 'icon': '', 'is_default': false},
          ],
        ),
      );

      final categories = await repository.list(type: CategoryType.income);

      expect(categories.single.name, 'Maosh');
      verify(() => dio.get<List<dynamic>>(path, queryParameters: {'type': 'income'})).called(1);
    });
  });

  group('create', () {
    test('sends name, type, and icon', () async {
      when(
        () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: path), data: {}),
      );

      await repository.create(name: 'Kiyim', type: CategoryType.expense, icon: '👕');

      verify(
        () => dio.post<Map<String, dynamic>>(
          path,
          data: {'name': 'Kiyim', 'type': 'expense', 'icon': '👕'},
        ),
      ).called(1);
    });

    test('surfaces a DRF validation error message', () async {
      when(
        () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
      ).thenThrow(
        dioErrorWithResponse(
          path: path,
          statusCode: 400,
          data: {
            'name': ['This field may not be blank.'],
          },
        ),
      );

      await expectLater(
        repository.create(name: '', type: CategoryType.expense),
        throwsA(
          isA<CategoryException>()
              .having((e) => e.message, 'message', 'This field may not be blank.'),
        ),
      );
    });
  });

  group('update', () {
    test('patches the category at its id-scoped endpoint', () async {
      when(
        () => dio.patch<Map<String, dynamic>>('/api/v1/categories/9/', data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: '/api/v1/categories/9/'), data: {}),
      );

      await repository.update(id: 9, name: 'Yangi', type: CategoryType.income);

      verify(
        () => dio.patch<Map<String, dynamic>>(
          '/api/v1/categories/9/',
          data: {'name': 'Yangi', 'type': 'income', 'icon': ''},
        ),
      ).called(1);
    });
  });

  group('delete', () {
    test('deletes the category and surfaces the delete fallback message on failure', () async {
      when(() => dio.delete<void>('/api/v1/categories/9/')).thenThrow(
        dioErrorWithResponse(path: '/api/v1/categories/9/', statusCode: 500, data: {}),
      );

      await expectLater(
        repository.delete(9),
        throwsA(
          isA<CategoryException>()
              .having((e) => e.message, 'message', "Kategoriyani o'chirib bo'lmadi"),
        ),
      );
    });
  });

  group('offline behaviour', () {
    Response<List<dynamic>> categoriesResponse() => Response(
          requestOptions: RequestOptions(path: path),
          data: [
            {'id': 1, 'name': 'Transport', 'type': 'expense', 'icon': '', 'is_default': true},
          ],
        );

    test('serves cached categories when the server is unreachable', () async {
      when(() => dio.get<List<dynamic>>(path, queryParameters: null))
          .thenAnswer((_) async => categoriesResponse());
      await repository.list();

      when(() => dio.get<List<dynamic>>(path, queryParameters: null))
          .thenThrow(dioConnectionError(path: path));

      final categories = await repository.list();

      expect(categories, hasLength(1));
      expect(categories.single.name, 'Transport');
    });

    test('caches each type filter separately', () async {
      when(() => dio.get<List<dynamic>>(path, queryParameters: null))
          .thenAnswer((_) async => categoriesResponse());
      await repository.list();

      when(
        () => dio.get<List<dynamic>>(path, queryParameters: {'type': 'income'}),
      ).thenThrow(dioConnectionError(path: path));

      // The unfiltered cache must not answer an income-filtered request.
      await expectLater(
        repository.list(type: CategoryType.income),
        throwsA(isA<DioException>()),
      );
    });
  });
}
