import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/analytics/domain/category_breakdown_entry.dart';
import 'package:mobile/features/analytics/presentation/providers/category_breakdown_controller.dart';

const _sliceColors = [
  Color(0xFF2563EB),
  Color(0xFFDC2626),
  Color(0xFF16A34A),
  Color(0xFFD97706),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
  Color(0xFF65A30D),
];

const _monthNames = [
  'Yanvar',
  'Fevral',
  'Mart',
  'Aprel',
  'May',
  'Iyun',
  'Iyul',
  'Avgust',
  'Sentabr',
  'Oktabr',
  'Noyabr',
  'Dekabr',
];

class CategoryBreakdownScreen extends ConsumerWidget {
  const CategoryBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(categoryBreakdownControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Xarajatlar tahlili')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(categoryBreakdownControllerProvider),
        ),
        data: (state) => Column(
          children: [
            _MonthSelector(year: state.year, month: state.month),
            Expanded(
              child: state.entries.isEmpty
                  ? const _EmptyView()
                  : _BreakdownChart(entries: state.entries),
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
    final controller = ref.read(categoryBreakdownControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: controller.previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${_monthNames[month - 1]} $year',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: controller.nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _BreakdownChart extends StatelessWidget {
  const _BreakdownChart({required this.entries});

  final List<CategoryBreakdownEntry> entries;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('uz');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 48,
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].percent,
                      color: _sliceColors[i % _sliceColors.length],
                      title: '${entries[i].percent.toStringAsFixed(0)}%',
                      radius: 64,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(entries.length, (i) {
            final entry = entries[i];
            return ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: _sliceColors[i % _sliceColors.length],
              ),
              title: Text(entry.category),
              trailing: Text(numberFormat.format(entry.total)),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "Bu oy uchun xarajat yo'q",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanlangan oyda xarajat tranzaksiyalari topilmadi',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
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
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
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
