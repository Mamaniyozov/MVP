import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/category_breakdown_entry.dart';

class CategoryBreakdownState {
  const CategoryBreakdownState({
    required this.year,
    required this.month,
    required this.entries,
  });

  final int year;
  final int month;
  final List<CategoryBreakdownEntry> entries;

  CategoryBreakdownState copyWith({int? year, int? month, List<CategoryBreakdownEntry>? entries}) {
    return CategoryBreakdownState(
      year: year ?? this.year,
      month: month ?? this.month,
      entries: entries ?? this.entries,
    );
  }
}

/// Loads the current user's expense-by-category breakdown for a given
/// month/year, defaulting to the current month, with prev/next navigation.
class CategoryBreakdownController extends AsyncNotifier<CategoryBreakdownState> {
  @override
  Future<CategoryBreakdownState> build() async {
    final now = DateTime.now();
    return _load(now.year, now.month);
  }

  Future<CategoryBreakdownState> _load(int year, int month) async {
    final entries = await ref.read(analyticsRepositoryProvider).categoryBreakdown(
          month: month,
          year: year,
        );
    return CategoryBreakdownState(year: year, month: month, entries: entries);
  }

  Future<void> _goTo(int year, int month) async {
    state = const AsyncLoading<CategoryBreakdownState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _load(year, month));
  }

  Future<void> previousMonth() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final total = current.year * 12 + (current.month - 1) - 1;
    await _goTo(total ~/ 12, total % 12 + 1);
  }

  Future<void> nextMonth() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final total = current.year * 12 + (current.month - 1) + 1;
    await _goTo(total ~/ 12, total % 12 + 1);
  }
}

final categoryBreakdownControllerProvider =
    AsyncNotifierProvider<CategoryBreakdownController, CategoryBreakdownState>(
  CategoryBreakdownController.new,
);
