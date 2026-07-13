enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? errorMessage;
}
