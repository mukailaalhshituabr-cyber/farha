// lib/presentation/screens/tailor/revenue/revenue_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';
import '../../../../routes/app_router.dart';

// ── Revenue data from real API ────────────────────────────────────────────────
final _revenueProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiConstants.revenueSummary);
  if (!res.success) throw Exception(res.message);
  final data = res.data as Map<String, dynamic>;
  return {
    'total':          (data['total_revenue']  as num?)?.toDouble() ?? 0.0,
    'pending_orders': (data['pending_orders'] as num?)?.toInt()    ?? 0,
    'this_week':      (data['week_revenue']   as num?)?.toDouble() ?? 0.0,
    'this_month':     (data['month_revenue']  as num?)?.toDouble() ?? 0.0,
    'this_year':      (data['year_revenue']   as num?)?.toDouble() ?? 0.0,
    'currency':       'CFA',
    'orders_count':   (data['total_orders']   as num?)?.toInt()    ?? 0,
  };
});

class RevenueDashboardScreen extends ConsumerWidget {
  const RevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l       = AppL10n.of(context);
    final revenue = ref.watch(_revenueProvider);
    final user    = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l.revenue,
            style: AppTheme.titleLarge.copyWith(
                fontFamily: 'PlusJakartaSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.onBackground, size: 22),
            onPressed: () => ref.invalidate(_revenueProvider),
          ),
        ],
      ),
      body: revenue.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.outline, size: 48),
            const SizedBox(height: 12),
            Text(l.somethingWrong,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => ref.invalidate(_revenueProvider),
                child: Text(l.retry)),
          ]),
        ),
        data: (data) => _RevenueBody(data: data, l: l, user: user),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.payout),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.account_balance_wallet_rounded),
        label: Text(l.requestPayout),
      ),
      bottomNavigationBar: const TailorBottomNav(currentIndex: 0),
    );
  }
}

class _RevenueBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppL10n l;
  final dynamic user;

  const _RevenueBody({required this.data, required this.l, required this.user});

  @override
  Widget build(BuildContext context) {
    final currency = data['currency'] as String? ?? 'CFA';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Total revenue hero card ─────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(l.totalRevenue,
                style: AppTheme.bodyMedium
                    .copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
              AppFormatters.currency(
                  (data['total'] as num).toDouble(),
                  symbol: currency),
              style: AppTheme.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(children: [
              _HeroStat(
                label: 'Active Orders',
                value: '${data['pending_orders']}',
              ),
              const SizedBox(width: 24),
              _HeroStat(
                label: 'Total Orders',
                value: '${data['orders_count']}',
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Period breakdown ─────────────────────────────────────
        Text('Earnings Breakdown',
            style: AppTheme.titleMedium
                .copyWith(fontFamily: 'PlusJakartaSans')),
        const SizedBox(height: 12),

        _PeriodCard(
          icon: Icons.calendar_view_week_rounded,
          label: l.thisWeek,
          amount: (data['this_week'] as num).toDouble(),
          currency: currency,
        ),
        const SizedBox(height: 10),
        _PeriodCard(
          icon: Icons.calendar_month_rounded,
          label: l.thisMonth,
          amount: (data['this_month'] as num).toDouble(),
          currency: currency,
        ),
        const SizedBox(height: 10),
        _PeriodCard(
          icon: Icons.calendar_today_rounded,
          label: l.thisYear,
          amount: (data['this_year'] as num).toDouble(),
          currency: currency,
        ),

        const SizedBox(height: 80), // FAB spacing
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: AppTheme.labelSmall.copyWith(color: Colors.white60)),
      Text(value,
          style: AppTheme.titleSmall
              .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
    ],
  );
}

class _PeriodCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final double   amount;
  final String   currency;
  const _PeriodCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outlineVariant, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Text(label, style: AppTheme.bodyMedium),
      const Spacer(),
      Text(
        AppFormatters.currency(amount, symbol: currency),
        style: AppTheme.titleSmall.copyWith(
            color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    ]),
  );
}
