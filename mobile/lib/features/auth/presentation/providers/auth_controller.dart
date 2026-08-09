import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/auth_event_bus.dart';
import 'package:mobile/core/api/token_storage.dart';
import 'package:mobile/core/storage/offline_cache.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required TokenStorage tokenStorage,
    required AuthEventBus eventBus,
    required OfflineCache offlineCache,
  })  : _repository = repository,
        _tokenStorage = tokenStorage,
        _offlineCache = offlineCache,
        super(const AuthState()) {
    _forceLogoutSubscription = eventBus.onForceLogout.listen((_) {
      _handleForceLogout();
    });
    _restoreSession();
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final OfflineCache _offlineCache;
  late final StreamSubscription<void> _forceLogoutSubscription;

  Future<void> _restoreSession() async {
    final hasSession = await _tokenStorage.hasValidSession();
    state = AuthState(
      status: hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> _handleForceLogout() async {
    await _clearSession();
  }

  /// Drops tokens *and* every cached payload — otherwise the next account to
  /// sign in on this device would be served the previous user's data offline.
  Future<void> _clearSession() async {
    await _tokenStorage.clear();
    await _offlineCache.clearAllCaches();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final tokens = await _repository.login(email: email, password: password);
      await _tokenStorage.saveTokens(access: tokens.access, refresh: tokens.refresh);
      state = const AuthState(status: AuthStatus.authenticated);
      return true;
    } on AuthException catch (error) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: error.message);
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: "Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring",
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String password2,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repository.register(email: email, password: password, password2: password2);
      final tokens = await _repository.login(email: email, password: password);
      await _tokenStorage.saveTokens(access: tokens.access, refresh: tokens.refresh);
      state = const AuthState(status: AuthStatus.authenticated);
      return true;
    } on AuthException catch (error) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: error.message);
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: "Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring",
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession();
  }

  @override
  void dispose() {
    _forceLogoutSubscription.cancel();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    eventBus: ref.watch(authEventBusProvider),
    offlineCache: ref.watch(offlineCacheProvider),
  );
});
