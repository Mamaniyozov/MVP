import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/analytics/domain/monthly_report.dart';
import 'package:mobile/features/analytics/presentation/month_names.dart';
import 'package:mobile/features/analytics/presentation/providers/monthly_report_controller.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(monthlyReportControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Oylik hisobot')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(monthlyReportControllerProvider),
        ),
        data: (state) => Column(
          children: [
            _MonthSelector(year: state.year, month: state.month),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _ReportBody(report: state.report),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(monthlyReportControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: controller.previousMonth, icon: const Icon(Icons.chevron_left)),
          Text(
            '${uzMonthNames[month - 1]} $year',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(onPressed: controller.nextMonth, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    if (report.previousMonth == null) {
      return Column(
        children: [
          _TotalsCard(totals: report.currentMonth),
          const SizedBox(height: 16),
          const _NoComparisonNotice(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalsCard(totals: report.currentMonth),
        const SizedBox(height: 16),
        _ChangeCard(changePercent: report.changePercent!),
        if (report.insights.isNotEmpty) ...[
          const SizedBox(height: 16),
          _InsightsCard(insights: report.insights),
        ],
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('uz');
    final isPositiveSavings = totals.savings >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _TotalTile(
                label: 'Daromad',
                value: numberFormat.format(totals.income),
                color: AppColors.income,
              ),
            ),
            Expanded(
              child: _TotalTile(
                label: 'Xarajat',
                value: numberFormat.format(totals.expense),
                color: AppColors.expense,
              ),
            ),
            Expanded(
              child: _TotalTile(
                label: "Jamg'arma",
                value: numberFormat.format(totals.savings),
                color: isPositiveSavings ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({required this.changePercent});

  final ChangePercent changePercent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "O'tgan oyga nisbatan",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _ChangeRow(label: 'Daromad', percent: changePercent.income, higherIsGood: true),
            _ChangeRow(label: 'Xarajat', percent: changePercent.expense, higherIsGood: false),
            _ChangeRow(label: "Jamg'arma", percent: changePercent.savings, higherIsGood: true),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.percent, required this.higherIsGood});

  final String label;
  final double? percent;
  final bool higherIsGood;

  @override
  Widget build(BuildContext context) {
    if (percent == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '-',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    final isIncrease = percent! >= 0;
    final isGood = isIncrease == higherIsGood;
    final color = isGood ? AppColors.income : AppColors.expense;
    final sign = isIncrease ? '+' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '$sign${percent!.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xulosalar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            for (final insight in insights)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(insight)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoComparisonNotice extends StatelessWidget {
  const _NoComparisonNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "O'tgan oy uchun ma'lumot yo'q, shuning uchun solishtirish mumkin emas",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
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
