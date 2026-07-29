/// A user-facing card error, already translated to Uzbek.
class CardException implements Exception {
  const CardException(this.message);

  final String message;

  @override
  String toString() => message;
}
