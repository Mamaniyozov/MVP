/// A user-facing auth error, already translated to Uzbek.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
