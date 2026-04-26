// lib/presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/admin_provider.dart';
import '../../../routes/app_router.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return AdminShell(
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString(),
            style: const TextStyle(color: Colors.white54))),
        data: (data) => _Dashboard(data: data),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Dashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final users   = data['users']   as Map<String, dynamic>? ?? {};
    final orders  = data['orders']  as Map<String, dynamic>? ?? {};
    final revenue = data['revenue'] as Map<String, dynamic>? ?? {};
    final payouts = data['payouts'] as Map<String, dynamic>? ?? {};
    final monthly = (data['monthly_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final pendingApprovals = data['pending_tailor_approvals'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Platform Overview',
            style: AppTheme.headlineMedium.copyWith(
                color: Colors.white, fontFamily: 'PlusJakartaSans')),
        const SizedBox(height: 4),
        Text('Real-time metrics across Farha marketplace',
            style: AppTheme.bodySmall.copyWith(color: Colors.white54)),
        const SizedBox(height: 24),

        // Alert banner for pending approvals
        if (pendingApprovals > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '$pendingApprovals tailor${pendingApprovals > 1 ? 's' : ''} waiting for approval',
                style: AppTheme.bodySmall.copyWith(color: Colors.orange),
              )),
              TextButton(
                onPressed: () => context.go(Routes.adminUsers),
                child: const Text('Review', style: TextStyle(color: Colors.orange)),
              ),
            ]),
          ),

        // Users row
        _SectionLabel('Users'),
        Row(children: [
          _StatCard('Total Users',   '${users['total'] ?? 0}',         Icons.people_alt_rounded,    AppColors.primary),
          const SizedBox(width: 12),
          _StatCard('Customers',     '${users['customers'] ?? 0}',     Icons.person_rounded,         const Color(0xFF4A90E2)),
          const SizedBox(width: 12),
          _StatCard('Tailors',       '${users['tailors'] ?? 0}',       Icons.content_cut_rounded,    const Color(0xFF7B5EA7)),
          const SizedBox(width: 12),
          _StatCard('New Today',     '${users['new_today'] ?? 0}',     Icons.fiber_new_rounded,      Colors.teal),
        ]),
        const SizedBox(height: 20),

        // Orders row
        _SectionLabel('Orders'),
        Row(children: [
          _StatCard('Total Orders',   '${orders['total'] ?? 0}',       Icons.receipt_long_rounded,   const Color(0xFFE2914A)),
          const SizedBox(width: 12),
          _StatCard('This Month',    '${orders['this_month'] ?? 0}',   Icons.calendar_month_rounded, const Color(0xFF4AE2A0)),
          const SizedBox(width: 12),
          _StatCard('Pending',       '${orders['pending'] ?? 0}',      Icons.hourglass_empty_rounded,Colors.amber),
          const SizedBox(width: 12),
          _StatCard('Cancelled',     '${orders['cancelled'] ?? 0}',    Icons.cancel_rounded,         AppColors.error),
        ]),
        const SizedBox(height: 20),

        // Revenue row
        _SectionLabel('Revenue (10% Commission)'),
        Row(children: [
          _StatCard('Platform Revenue',
              AppFormatters.currency((revenue['total_platform_revenue'] as num? ?? 0).toDouble()),
              Icons.trending_up_rounded, Colors.green),
          const SizedBox(width: 12),
          _StatCard('Total GMV',
              AppFormatters.currency((revenue['total_gmv'] as num? ?? 0).toDouble()),
              Icons.attach_money_rounded, const Color(0xFF4A90E2)),
          const SizedBox(width: 12),
          _StatCard('This Month',
              AppFormatters.currency((revenue['month_platform_revenue'] as num? ?? 0).toDouble()),
              Icons.calendar_today_rounded, Colors.teal),
          const SizedBox(width: 12),
          _StatCard('Pending Payouts',
              AppFormatters.currency((payouts['pending_amount'] as num? ?? 0).toDouble()),
              Icons.account_balance_wallet_rounded,
              (payouts['pending_count'] ?? 0) > 0 ? Colors.orange : Colors.grey),
        ]),
        const SizedBox(height: 28),

        // Monthly chart (simple bar representation)
        if (monthly.isNotEmpty) ...[
          _SectionLabel('Monthly GMV — Last 6 Months'),
          _MonthlyChart(monthly: monthly),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: AppTheme.labelMedium.copyWith(
        color: Colors.white54, letterSpacing: 0.8)),
  );
}

class _StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C0C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
        ]),
        const SizedBox(height: 12),
        Text(value, style: AppTheme.headlineSmall.copyWith(
            color: Colors.white, fontWeight: FontWeight.w700,
            fontFamily: 'PlusJakartaSans')),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.labelSmall.copyWith(color: Colors.white54)),
      ]),
    ),
  );
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  const _MonthlyChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final maxVal = monthly.fold<double>(
        1, (m, e) => (e['gmv'] as num? ?? 0).toDouble() > m
            ? (e['gmv'] as num).toDouble() : m);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C0C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: monthly.map((m) {
          final gmv    = (m['gmv'] as num? ?? 0).toDouble();
          final height = (gmv / maxVal) * 100;
          final month  = (m['month'] as String? ?? '').replaceFirst(RegExp(r'^\d{4}-'), '');
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  height: height.clamp(4, 100),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(month, style: AppTheme.labelSmall.copyWith(
                    color: Colors.white38, fontSize: 10)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
