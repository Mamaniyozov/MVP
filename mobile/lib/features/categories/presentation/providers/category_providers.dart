import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/categories/data/category_repository.dart';
import 'package:mobile/features/categories/domain/category.dart';

/// Categories for a given transaction type, fetched fresh each time the
/// provider is watched with a new [type] (cached per-type by Riverpod's
/// family mechanism for the lifetime of the widget tree that watches it).
final categoriesByTypeProvider =
    FutureProvider.family<List<Category>, CategoryType>((ref, type) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.list(type: type);
});

/// All categories regardless of type — used to resolve a transaction's
/// category id to its name/icon for display in the transaction list.
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.list();
});
