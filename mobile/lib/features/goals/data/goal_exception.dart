/// A user-facing goal error, already translated to Uzbek.
class GoalException implements Exception {
  const GoalException(this.message);

  final String message;

  @override
  String toString() => message;
}
