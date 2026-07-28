/// A user-facing category error, already translated to Uzbek.
class CategoryException implements Exception {
  const CategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
