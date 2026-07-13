import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/auth_event_bus.dart';
import 'package:mobile/core/api/auth_interceptor.dart';
import 'package:mobile/core/api/token_storage.dart';
import 'package:mobile/core/config/env.dart';

Dio _buildBaseDio() {
  return Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );
}

/// The shared Dio instance the whole app uses for API calls. A second,
/// interceptor-free Dio is used internally only for the token refresh call,
/// so a failed refresh can't recursively trigger itself.
final apiClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final eventBus = ref.watch(authEventBusProvider);

  final refreshDio = _buildBaseDio();
  final dio = _buildBaseDio();

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshDio: refreshDio,
      eventBus: eventBus,
    ),
  );

  return dio;
});
