import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/categories/data/category_exception.dart';
import 'package:mobile/features/categories/data/category_repository.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/categories/presentation/providers/category_providers.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriyalar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addCategory),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(allCategoriesProvider),
        ),
        data: (categories) {
          final expense = categories.where((c) => c.type == CategoryType.expense).toList();
          final income = categories.where((c) => c.type == CategoryType.income).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allCategoriesProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const _SectionHeader(title: 'Xarajat kategoriyalari'),
                for (final category in expense) _CategoryTile(category: category),
                const SizedBox(height: 8),
                const _SectionHeader(title: 'Daromad kategoriyalari'),
                for (final category in income) _CategoryTile(category: category),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final Category category;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kategoriyani o'chirish"),
        content: Text("'${category.name}' kategoriyasini o'chirmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(categoryRepositoryProvider).delete(category.id);
      ref.invalidate(allCategoriesProvider);
    } on CategoryException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProtected = category.isDefault;

    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          category.type == CategoryType.income ? Icons.arrow_downward : Icons.arrow_upward,
        ),
      ),
      title: Text(category.name),
      subtitle: isProtected ? const Text('Standart kategoriya') : null,
      trailing: isProtected
          ? Icon(
              Icons.lock_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(AppRoutes.editCategory, extra: category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.expense),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Qayta urinish')),
          ],
        ),
      ),
    );
  }
}
