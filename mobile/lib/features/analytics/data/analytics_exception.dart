/// A user-facing analytics error, already translated to Uzbek.
class AnalyticsException implements Exception {
  const AnalyticsException(this.message);

  final String message;

  @override
  String toString() => message;
}
