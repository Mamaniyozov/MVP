import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/analytics/domain/monthly_trend_entry.dart';
import 'package:mobile/features/analytics/presentation/month_names.dart';
import 'package:mobile/features/analytics/presentation/providers/monthly_trend_controller.dart';

class MonthlyTrendScreen extends ConsumerWidget {
  const MonthlyTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(monthlyTrendControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Oylik dinamika')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(monthlyTrendControllerProvider),
        ),
        data: (entries) {
          final hasData = entries.any((e) => e.income > 0 || e.expense > 0);
          if (!hasData) return const _EmptyView();
          return _TrendBody(entries: entries);
        },
      ),
    );
  }
}

String _monthLabel(String yyyyMm) {
  final parts = yyyyMm.split('-');
  final index = int.parse(parts[1]) - 1;
  final name = uzMonthNames[index];
  return name.length > 3 ? name.substring(0, 3) : name;
}

class _TrendBody extends StatelessWidget {
  const _TrendBody({required this.entries});

  final List<MonthlyTrendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('uz');
    final maxValue = entries
        .expand((e) => [e.income, e.expense])
        .fold<double>(0, (max, v) => v > max ? v : max);
    final chartMax = maxValue <= 0 ? 1.0 : maxValue * 1.15;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Legend(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
              child: SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    maxY: chartMax,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: chartMax / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final entry = entries[groupIndex];
                          final label = rodIndex == 0 ? 'Daromad' : 'Xarajat';
                          final value = rodIndex == 0 ? entry.income : entry.expense;
                          return BarTooltipItem(
                            '$label\n${numberFormat.format(value)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _monthLabel(entries[index].month),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < entries.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: entries[i].income,
                              color: AppColors.income,
                              width: 9,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                            BarChartRodData(
                              toY: entries[i].expense,
                              color: AppColors.expense,
                              width: 9,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ],
                          barsSpace: 4,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (final entry in entries.reversed)
                  _MonthRow(entry: entry, numberFormat: numberFormat),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.income, label: 'Daromad'),
        SizedBox(width: 20),
        _LegendDot(color: AppColors.expense, label: 'Xarajat'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.entry, required this.numberFormat});

  final MonthlyTrendEntry entry;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final year = entry.month.split('-')[0];
    final savings = entry.income - entry.expense;
    return ListTile(
      title: Text('${uzMonthNames[int.parse(entry.month.split('-')[1]) - 1]} $year'),
      subtitle: Text(
        'Daromad ${numberFormat.format(entry.income)} · Xarajat ${numberFormat.format(entry.expense)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        numberFormat.format(savings),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: savings >= 0 ? AppColors.income : AppColors.expense,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text("So'nggi 6 oyda tranzaksiya yo'q", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              "Daromad yoki xarajat qo'shsangiz, dinamika shu yerda ko'rinadi",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
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
