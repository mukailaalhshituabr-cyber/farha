// lib/presentation/screens/tailor/dashboard/tailor_dashboard_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/order_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';
import '../../../../routes/app_router.dart';

class TailorDashboardScreen extends ConsumerWidget {
  const TailorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l          = AppL10n.of(context);
    final user       = ref.watch(authProvider).user;
    final orderState = ref.watch(orderProvider);
    final hour       = DateTime.now().hour;
    final greeting   = hour < 12 ? l.goodMorning
        : hour < 17  ? l.goodAfternoon : l.goodEvening;

    final pending = orderState.items.where((o) => o.status == 'pending').length;
    final cutting = orderState.items.where((o) => o.status == 'cutting').length;
    final sewing  = orderState.items.where((o) => o.status == 'sewing').length;
    final ready   = orderState.items.where((o) => o.status == 'ready').length;
    final recent  = orderState.items.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Farha',
            style: AppTheme.titleLarge.copyWith(
              fontFamily: 'PlusJakartaSans',
              color: AppColors.primary,
              letterSpacing: 2,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.onBackground),
            onPressed: () => context.push(Routes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.onBackground),
            tooltip: l.logout,
            onPressed: () => _confirmLogout(context, ref, l),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.read(orderProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting banner ──────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting,',
                          style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.8))),
                      const SizedBox(height: 2),
                      Text(user?.fullName ?? l.tailor,
                          style: AppTheme.headlineMedium.copyWith(
                              color: AppColors.onPrimary,
                              fontFamily: 'PlusJakartaSans')),
                      const SizedBox(height: 4),
                      Text(l.digitalAtelierBuzzing,
                          style: AppTheme.bodySmall.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.75))),
                    ],
                  )),
                  GestureDetector(
                    onTap: () => context.push(Routes.tailorProfile),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.onPrimary.withValues(alpha: 0.2),
                      backgroundImage: user?.profilePhoto != null
                          ? CachedNetworkImageProvider(
                              user!.profilePhoto!,
                              cacheKey: user.profilePhoto,
                            )
                          : null,
                      child: user?.profilePhoto == null
                          ? Text(
                              AppFormatters.initials(user?.fullName ?? 'T'),
                              style: AppTheme.titleMedium
                                  .copyWith(color: AppColors.onPrimary),
                            )
                          : null,
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Stage counters ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: [
                    _StageCounter(label: l.stagePending, count: pending,
                        icon: Icons.schedule_rounded,       color: AppColors.warning),
                    _StageCounter(label: l.stageCutting, count: cutting,
                        icon: Icons.content_cut_rounded,    color: AppColors.info),
                    _StageCounter(label: l.stageSewing,  count: sewing,
                        icon: Icons.checkroom_rounded,      color: const Color(0xFF7C3AED)),
                    _StageCounter(label: l.stageReady,   count: ready,
                        icon: Icons.inventory_2_rounded,    color: AppColors.success),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Revenue card ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.todaysRevenue,
                              style: AppTheme.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant)),
                          Text('—',
                              style: AppTheme.titleLarge.copyWith(
                                  color: AppColors.primary)),
                        ]),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(100)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.trending_up_rounded,
                            color: AppColors.success, size: 14),
                        const SizedBox(width: 4),
                        Text(l.revenue,
                            style: AppTheme.labelSmall.copyWith(
                                color: AppColors.success)),
                      ]),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 24),

              // ── Recent orders ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.recentOrders,
                        style: AppTheme.titleLarge.copyWith(
                            fontFamily: 'PlusJakartaSans')),
                    TextButton(
                        onPressed: () =>
                            context.push(Routes.tailorOrderManagement),
                        child: Text(l.viewAll,
                            style: AppTheme.labelMedium.copyWith(
                                color: AppColors.primary))),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (orderState.isLoading)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else if (orderState.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3), width: 0.5)),
                    child: Column(children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 36),
                      const SizedBox(height: 10),
                      Text(AppL10n.of(context).somethingWrong,
                          style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.onErrorContainer),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(orderProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(AppL10n.of(context).retry),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.error),
                      ),
                    ]),
                  ),
                )
              else if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.outlineVariant, width: 0.5)),
                    child: Text(l.noOrdersYet,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant)),
                  ),
                )
              else
                ...recent.map((o) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _TailorOrderCard(
                    order: o,
                    onTap: () => context.push('/tailor/order/${o.id}'),
                    onUpdateStatus: (s) => ref
                        .read(orderProvider.notifier)
                        .updateStatus(o.id, s),
                  ),
                )),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TailorBottomNav(currentIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.addEditProduct),
        backgroundColor: AppColors.primary,
        tooltip: l.listNewGarment,
        child: const Icon(Icons.add_rounded, color: AppColors.onPrimary),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, AppL10n l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmBody),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel)),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go(Routes.onboarding);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100))),
              child: Text(l.logout)),
        ],
      ),
    );
  }
}

class _StageCounter extends StatelessWidget {
  final String label;
  final int    count;
  final IconData icon;
  final Color  color;
  const _StageCounter({
    required this.label, required this.count,
    required this.icon,  required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text('$count',
          style: AppTheme.headlineSmall.copyWith(
              color: color, fontFamily: 'PlusJakartaSans')),
      Text(label,
          style: AppTheme.labelSmall.copyWith(color: color),
          textAlign: TextAlign.center),
    ]),
  );
}

class _TailorOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final void Function(String) onUpdateStatus;

  const _TailorOrderCard({
    required this.order,
    required this.onTap,
    required this.onUpdateStatus,
  });

  static const _next = {
    'pending':   'cutting',
    'confirmed': 'cutting',
    'cutting':   'sewing',
    'sewing':    'ready',
    'ready':     'delivered',
  };

  @override
  Widget build(BuildContext context) {
    final l           = AppL10n.of(context);
    final statusColor = OrderStatusHelper.color(order.status, context);
    final next        = _next[order.status];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.outlineVariant, width: 0.5)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(order.customerName,
                  style: AppTheme.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                  '${AppFormatters.orderRef(order.referenceNumber)} • '
                  '${order.productName ?? "Custom"}',
                  style: AppTheme.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100)),
                child: Text(
                    OrderStatusHelper.label(order.status),
                    style: AppTheme.labelSmall.copyWith(
                        color: statusColor))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppFormatters.currency(
                  order.totalAmount, symbol: order.currency),
                  style: AppTheme.labelMedium),
              if (!order.isFullyPaid)
                Text(
                    l.balanceDue(AppFormatters.currency(
                        order.balanceDue, symbol: order.currency)),
                    style: AppTheme.bodySmall.copyWith(
                        color: AppColors.warning)),
            ]),
            const Spacer(),
            if (next != null)
              ElevatedButton(
                onPressed: () => onUpdateStatus(next),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: AppTheme.labelSmall,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100))),
                child: Text(
                    '→ ${OrderStatusHelper.label(next)}'),
              ),
          ]),
        ]),
      ),
    );
  }
}
