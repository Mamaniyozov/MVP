import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (
        icon: Icons.receipt_long_outlined,
        title: 'Tranzaksiyalar',
        subtitle: "Daromad va xarajatlaringizni ko'ring, yangi qo'shing",
        tone: AppColors.brand,
        route: AppRoutes.transactions,
      ),
      (
        icon: Icons.savings_outlined,
        title: 'Maqsadlar',
        subtitle: "Jamg'arma maqsadlaringizni kuzatib boring",
        tone: AppColors.accent,
        route: AppRoutes.goals,
      ),
      (
        icon: Icons.pie_chart_outline,
        title: 'Xarajatlar tahlili',
        subtitle: "Kategoriya bo'yicha xarajatlaringizni ko'ring",
        tone: AppColors.expense,
        route: AppRoutes.categoryBreakdown,
      ),
      (
        icon: Icons.summarize_outlined,
        title: 'Oylik hisobot',
        subtitle: "Joriy va o'tgan oyni solishtiring",
        tone: AppColors.income,
        route: AppRoutes.monthlyReport,
      ),
      (
        icon: Icons.show_chart,
        title: 'Oylik dinamika',
        subtitle: "So'nggi 6 oy davomida daromad va xarajat",
        tone: AppColors.brand,
        route: AppRoutes.monthlyTrend,
      ),
      (
        icon: Icons.label_outline,
        title: 'Kategoriyalar',
        subtitle: "O'zingizning kategoriyalaringizni boshqaring",
        tone: AppColors.brandStrong,
        route: AppRoutes.categories,
      ),
      (
        icon: Icons.credit_card_outlined,
        title: 'Kartalar',
        subtitle: "Kartalaringizni qo'shing va boshqaring",
        tone: AppColors.income,
        route: AppRoutes.cards,
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              onLogout: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _StaggeredEntrance(
                  index: index,
                  child: _DashboardCard(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                    tone: item.tone,
                    onTap: () => context.push(item.route),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand-gradient hero header with greeting and a subtle ledger-line motif.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 12, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Ledger-line motif echoing the web app's auth panel.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _LedgerLinesPainter()),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hisob',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    tooltip: 'Chiqish',
                    onPressed: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Xush kelibsiz 👋',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                "Har bir so'm — o'z qatorida.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double y = 24; y < size.height + 40; y += 28) {
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fade + slide entrance, staggered by list index. Uses an implicit
/// animation (no controller to dispose) and respects reduced motion.
class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return widget.child;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tone, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
