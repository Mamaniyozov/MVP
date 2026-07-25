/// A user-facing transaction error, already translated to Uzbek.
class TransactionException implements Exception {
  const TransactionException(this.message);

  final String message;

  @override
  String toString() => message;
}
