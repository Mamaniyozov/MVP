import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/auth_event_bus.dart';
import 'package:mobile/core/api/auth_interceptor.dart';
import 'package:mobile/core/api/token_storage.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mock_dio.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockAuthEventBus extends Mock implements AuthEventBus {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockDio refreshDio;
  late MockAuthEventBus eventBus;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    tokenStorage = MockTokenStorage();
    refreshDio = MockDio();
    eventBus = MockAuthEventBus();
    interceptor = AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshDio: refreshDio,
      eventBus: eventBus,
    );
  });

  group('AuthInterceptor.onRequest', () {
    test('attaches Bearer token to protected endpoints when token exists', () async {
      when(() => tokenStorage.accessToken).thenAnswer((_) async => 'valid_access_token');
      final options = RequestOptions(path: '/api/v1/transactions/');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], equals('Bearer valid_access_token'));
    });

    test('does not attach Bearer token to public endpoints', () async {
      when(() => tokenStorage.accessToken).thenAnswer((_) async => 'valid_access_token');
      final options = RequestOptions(path: '/api/v1/auth/login/');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('AuthInterceptor.onError', () {
    test('passes non-401 error through unchanged', () async {
      final options = RequestOptions(path: '/api/v1/transactions/');
      final error = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 400),
      );
      final handler = ErrorInterceptorHandler();

      await interceptor.onError(error, handler);

      verifyNever(() => tokenStorage.refreshToken);
    });

    test('clears session and emits force-logout when refresh token is null', () async {
      when(() => tokenStorage.refreshToken).thenAnswer((_) async => null);
      when(() => tokenStorage.clear()).thenAnswer((_) async {});
      when(() => eventBus.emitForceLogout()).returnsWith(null);

      final options = RequestOptions(path: '/api/v1/transactions/');
      final error = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );
      final handler = ErrorInterceptorHandler();

      await interceptor.onError(error, handler);

      verify(() => tokenStorage.clear()).called(1);
      verify(() => eventBus.emitForceLogout()).called(1);
    });

    test('refreshes access token and retries request on 401', () async {
      when(() => tokenStorage.refreshToken).thenAnswer((_) async => 'old_refresh_token');
      when(() => refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh/',
        data: {'refresh': 'old_refresh_token'},
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/refresh/'),
        statusCode: 200,
        data: {'access': 'new_access_token'},
      ));
      when(() => tokenStorage.saveAccessToken('new_access_token')).thenAnswer((_) async {});
      when(() => tokenStorage.accessToken).thenAnswer((_) async => 'new_access_token');

      final options = RequestOptions(path: '/api/v1/transactions/');
      final error = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );
      final handler = ErrorInterceptorHandler();

      final retriedResponse = Response(
        requestOptions: options,
        statusCode: 200,
        data: {'results': []},
      );
      when(() => refreshDio.fetch<dynamic>(any())).thenAnswer((_) async => retriedResponse);

      await interceptor.onError(error, handler);

      verify(() => tokenStorage.saveAccessToken('new_access_token')).called(1);
      verify(() => refreshDio.fetch<dynamic>(any())).called(1);
    });
  });
}
