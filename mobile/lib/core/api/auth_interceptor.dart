import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mobile/core/api/auth_event_bus.dart';
import 'package:mobile/core/api/token_storage.dart';

/// Attaches the stored access token to every request and transparently
/// refreshes it on a 401. If the refresh itself fails, clears the session
/// and emits a force-logout event so the app can route back to login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.refreshDio,
    required this.eventBus,
  });

  final TokenStorage tokenStorage;
  final Dio refreshDio;
  final AuthEventBus eventBus;

  Completer<bool>? _refreshCompleter;

  static const _publicPaths = [
    '/api/v1/auth/login/',
    '/api/v1/auth/register/',
    '/api/v1/auth/refresh/',
  ];

  bool _isPublicPath(String path) => _publicPaths.any(path.contains);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicPath(options.path)) {
      final accessToken = await tokenStorage.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final requestPath = err.requestOptions.path;
    final isRetried = err.requestOptions.extra['isRetried'] == true;

    if (!isUnauthorized || _isPublicPath(requestPath) || isRetried) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed) {
      await tokenStorage.clear();
      eventBus.emitForceLogout();
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await tokenStorage.accessToken;
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      retryOptions.extra['isRetried'] = true;
      final response = await refreshDio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Coalesces concurrent 401s into a single refresh call — every caller
  /// awaits the same in-flight attempt instead of racing the refresh token.
  Future<bool> _refreshAccessToken() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    _performRefresh().then((result) {
      completer.complete(result);
      _refreshCompleter = null;
    });
    return completer.future;
  }

  Future<bool> _performRefresh() async {
    try {
      final refreshToken = await tokenStorage.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh/',
        data: {'refresh': refreshToken},
      );
      final newAccess = response.data?['access'] as String?;
      if (newAccess == null || newAccess.isEmpty) {
        return false;
      }
      await tokenStorage.saveAccessToken(newAccess);
      return true;
    } catch (_) {
      return false;
    }
  }
}
