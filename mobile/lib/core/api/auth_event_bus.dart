import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the (widget-less) Dio interceptor signal "the session is no longer
/// valid" without depending on AuthController directly — avoids a provider
/// dependency cycle between the API client and the auth state.
class AuthEventBus {
  final _forceLogoutController = StreamController<void>.broadcast();

  Stream<void> get onForceLogout => _forceLogoutController.stream;

  void emitForceLogout() {
    if (!_forceLogoutController.isClosed) {
      _forceLogoutController.add(null);
    }
  }

  void dispose() {
    _forceLogoutController.close();
  }
}

final authEventBusProvider = Provider<AuthEventBus>((ref) {
  final bus = AuthEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});
