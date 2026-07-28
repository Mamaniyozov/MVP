import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bosh sahifa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Chiqish',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardCard(
              icon: Icons.receipt_long_outlined,
              title: 'Tranzaksiyalar',
              subtitle: "Daromad va xarajatlaringizni ko'ring, yangi qo'shing",
              onTap: () => context.push(AppRoutes.transactions),
            ),
            const SizedBox(height: 12),
            _DashboardCard(
              icon: Icons.savings_outlined,
              title: 'Maqsadlar',
              subtitle: "Jamg'arma maqsadlaringizni kuzatib boring",
              onTap: () => context.push(AppRoutes.goals),
            ),
            const SizedBox(height: 12),
            _DashboardCard(
              icon: Icons.pie_chart_outline,
              title: 'Xarajatlar tahlili',
              subtitle: 'Kategoriya bo\'yicha xarajatlaringizni ko\'ring',
              onTap: () => context.push(AppRoutes.categoryBreakdown),
            ),
            const SizedBox(height: 12),
            _DashboardCard(
              icon: Icons.summarize_outlined,
              title: 'Oylik hisobot',
              subtitle: 'Joriy va o\'tgan oyni solishtiring',
              onTap: () => context.push(AppRoutes.monthlyReport),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
