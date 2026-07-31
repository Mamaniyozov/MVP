import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/goals/data/goal_exception.dart';
import 'package:mobile/features/goals/data/goal_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mock_dio.dart';

void main() {
  late MockDio dio;
  late GoalRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    dio = MockDio();
    repository = GoalRepository(dio);
  });

  group('list', () {
    test('parses the unpaginated goal array', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/goals/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/goals/'),
          data: [
            {
              'id': 1,
              'name': 'Yangi mashina',
              'target_amount': '5000000.00',
              'current_amount': '1250000.00',
              'deadline': '2027-01-01',
              'progress_percent': '25.00',
            },
          ],
        ),
      );

      final goals = await repository.list();

      expect(goals, hasLength(1));
      expect(goals.single.name, 'Yangi mashina');
      expect(goals.single.targetAmount, 5000000.0);
      expect(goals.single.currentAmount, 1250000.0);
      expect(goals.single.progressPercent, 25.0);
      expect(goals.single.deadline, DateTime(2027, 1, 1));
    });

    test('a goal without a deadline parses to null', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/goals/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/goals/'),
          data: [
            {
              'id': 2,
              'name': "Zaxira jamg'arma",
              'target_amount': '1000000.00',
              'current_amount': '0.00',
              'deadline': null,
              'progress_percent': '0.00',
            },
          ],
        ),
      );

      final goals = await repository.list();

      expect(goals.single.deadline, isNull);
    });

    test('throws GoalException with a connection message when there is no response', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/goals/'))
          .thenThrow(dioConnectionError(path: '/api/v1/goals/'));

      await expectLater(
        repository.list(),
        throwsA(
          isA<GoalException>().having(
            (e) => e.message,
            'message',
            "Serverga ulanib bo'lmadi. Internet aloqasini tekshiring",
          ),
        ),
      );
    });

    test('throws GoalException with a generic message on a server error response', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/goals/')).thenThrow(
        dioErrorWithResponse(path: '/api/v1/goals/', statusCode: 500),
      );

      await expectLater(
        repository.list(),
        throwsA(
          isA<GoalException>()
              .having((e) => e.message, 'message', "Ma'lumotlarni yuklab bo'lmadi"),
        ),
      );
    });

    test('wraps unexpected non-Dio errors in a fallback GoalException', () async {
      when(() => dio.get<List<dynamic>>('/api/v1/goals/')).thenThrow(Exception('boom'));

      await expectLater(
        repository.list(),
        throwsA(
          isA<GoalException>().having(
            (e) => e.message,
            'message',
            "Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring",
          ),
        ),
      );
    });
  });

  group('create', () {
    test('sends the target amount fixed to 2 decimals and formats the deadline', () async {
      when(
        () => dio.post<Map<String, dynamic>>('/api/v1/goals/', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/api/v1/goals/'), data: {}),
      );

      await repository.create(
        name: 'Sayohat',
        targetAmount: 2500000,
        deadline: DateTime(2026, 3, 5),
      );

      final captured = verify(
        () => dio.post<Map<String, dynamic>>('/api/v1/goals/', data: captureAny(named: 'data')),
      ).captured.single as Map<String, dynamic>;

      expect(captured['name'], 'Sayohat');
      expect(captured['target_amount'], '2500000.00');
      expect(captured['deadline'], '2026-03-05');
    });

    test('omits the deadline key entirely when none is given', () async {
      when(
        () => dio.post<Map<String, dynamic>>('/api/v1/goals/', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/api/v1/goals/'), data: {}),
      );

      await repository.create(name: 'Sayohat', targetAmount: 100, deadline: null);

      final captured = verify(
        () => dio.post<Map<String, dynamic>>('/api/v1/goals/', data: captureAny(named: 'data')),
      ).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('deadline'), isFalse);
    });

    test('surfaces the first DRF validation error message', () async {
      when(
        () => dio.post<Map<String, dynamic>>('/api/v1/goals/', data: any(named: 'data')),
      ).thenThrow(
        dioErrorWithResponse(
          path: '/api/v1/goals/',
          statusCode: 400,
          data: {
            'target_amount': ['Ensure this value is greater than 0.'],
          },
        ),
      );

      await expectLater(
        repository.create(name: 'Sayohat', targetAmount: 0, deadline: null),
        throwsA(
          isA<GoalException>().having(
            (e) => e.message,
            'message',
            'Ensure this value is greater than 0.',
          ),
        ),
      );
    });

    test('falls back to a generic write-error message when the response has no field errors',
        () async {
      when(
        () => dio.post<Map<String, dynamic>>('/api/v1/goals/', data: any(named: 'data')),
      ).thenThrow(
        dioErrorWithResponse(path: '/api/v1/goals/', statusCode: 500, data: {}),
      );

      await expectLater(
        repository.create(name: 'Sayohat', targetAmount: 100, deadline: null),
        throwsA(
          isA<GoalException>()
              .having((e) => e.message, 'message', "Maqsadni saqlab bo'lmadi"),
        ),
      );
    });
  });

  group('addProgress', () {
    test('posts the fixed-precision amount to the goal-specific endpoint', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/v1/goals/7/add-progress/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/goals/7/add-progress/'),
          data: {},
        ),
      );

      await repository.addProgress(goalId: 7, amount: 15000.5);

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/v1/goals/7/add-progress/',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(captured['amount'], '15000.50');
    });

    test('throws GoalException with the add-progress fallback message', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/v1/goals/7/add-progress/',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        dioErrorWithResponse(
          path: '/api/v1/goals/7/add-progress/',
          statusCode: 500,
          data: {},
        ),
      );

      await expectLater(
        repository.addProgress(goalId: 7, amount: 100),
        throwsA(
          isA<GoalException>()
              .having((e) => e.message, 'message', "Progressni qo'shib bo'lmadi"),
        ),
      );
    });
  });
}
