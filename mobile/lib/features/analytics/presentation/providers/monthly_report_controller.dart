import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/monthly_report.dart';

class MonthlyReportState {
  const MonthlyReportState({required this.year, required this.month, required this.report});

  final int year;
  final int month;
  final MonthlyReport report;
}

/// Loads the current user's monthly report for a given month/year,
/// defaulting to the current month, with prev/next navigation.
class MonthlyReportController extends AsyncNotifier<MonthlyReportState> {
  @override
  Future<MonthlyReportState> build() async {
    final now = DateTime.now();
    return _load(now.year, now.month);
  }

  Future<MonthlyReportState> _load(int year, int month) async {
    final report = await ref.read(analyticsRepositoryProvider).monthlyReport(
          month: month,
          year: year,
        );
    return MonthlyReportState(year: year, month: month, report: report);
  }

  Future<void> _goTo(int year, int month) async {
    state = const AsyncLoading<MonthlyReportState>().copyWithPrevious(state);
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

final monthlyReportControllerProvider =
    AsyncNotifierProvider<MonthlyReportController, MonthlyReportState>(
  MonthlyReportController.new,
);
