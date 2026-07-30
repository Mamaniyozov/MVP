import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/monthly_trend_entry.dart';

/// Loads the last 6 months of income/expense totals for the trend chart.
/// No month navigation — it's always a rolling window ending this month.
final monthlyTrendControllerProvider = FutureProvider<List<MonthlyTrendEntry>>((ref) {
  return ref.watch(analyticsRepositoryProvider).monthlyTrend(months: 6);
});
