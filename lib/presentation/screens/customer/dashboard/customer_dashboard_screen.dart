// lib/presentation/screens/customer/dashboard/customer_dashboard_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/order_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';
import '../../../../routes/app_router.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l           = AppL10n.of(context);
    final user        = ref.watch(authProvider).user;
    final orderState  = ref.watch(orderProvider);
    final activeOrders = orderState.items.where((o) => o.isActive).take(3).toList();
    final hour        = DateTime.now().hour;
    final greeting    = hour < 12 ? l.goodMorning
        : hour < 17  ? l.goodAfternoon : l.goodEvening;

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
            icon: const Icon(Icons.search_rounded, color: AppColors.onBackground),
            onPressed: () => context.push(Routes.search),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.onBackground),
            onPressed: () => context.push(Routes.cart),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.onBackground),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting,',
                          style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.8))),
                      const SizedBox(height: 2),
                      Text(user?.firstName ?? 'Welcome!',
                          style: AppTheme.headlineMedium.copyWith(
                              color: AppColors.onPrimary,
                              fontFamily: 'PlusJakartaSans')),
                    ],
                  )),
                  GestureDetector(
                    onTap: () => context.push(Routes.customerProfile),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                      backgroundImage: user?.profilePhoto != null
                          ? CachedNetworkImageProvider(
                              user!.profilePhoto!,
                              cacheKey: user.profilePhoto,
                            )
                          : null,
                      child: user?.profilePhoto == null
                          ? Text(
                              AppFormatters.initials(user?.fullName ?? 'U'),
                              style: AppTheme.titleMedium.copyWith(
                                  color: AppColors.onPrimary),
                            )
                          : null,
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Quick actions ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _QuickActionCard(
                    icon: Icons.shopping_bag_outlined,
                    label: l.readyMade,
                    subtitle: l.shopNow,
                    color: AppColors.primaryFixed,
                    iconColor: AppColors.primary,
                    onTap: () => context.push(Routes.productListing),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickActionCard(
                    icon: Icons.straighten_rounded,
                    label: l.customMade,
                    subtitle: l.orderNow,
                    color: AppColors.secondaryContainer,
                    iconColor: AppColors.secondary,
                    onTap: () => context.push(Routes.customOrderMeasurements),
                  )),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Active orders ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.activeOrders,
                        style: AppTheme.titleLarge.copyWith(
                            fontFamily: 'PlusJakartaSans')),
                    TextButton(
                      onPressed: () => context.push(Routes.orderHistory),
                      child: Text(l.viewAll,
                          style: AppTheme.labelMedium.copyWith(
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (orderState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(
                      color: AppColors.primary)))
              else if (orderState.error != null)
                _ErrorCard(
                  message: l.somethingWrong,
                  retryLabel: l.retry,
                  onRetry: () => ref.read(orderProvider.notifier).refresh(),
                )
              else if (activeOrders.isEmpty)
                _EmptyOrdersCard(
                  noActiveOrders: l.noActiveOrders,
                  ordersAppearHere: l.ordersAppearHere,
                )
              else
                ...activeOrders.map((order) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _ActiveOrderCard(
                    order: order,
                    trackLabel: l.trackOrderArrow,
                    completeLabel: l.completePercent(order.progressPercent),
                    inProgressLabel: l.inProgress,
                    onTap: () => context.push(
                        '/customer/order/track/${order.id}'),
                  ),
                )),

              const SizedBox(height: 24),

              // ── Featured tailors ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l.featuredTailors,
                    style: AppTheme.titleLarge.copyWith(
                        fontFamily: 'PlusJakartaSans')),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    _FeaturedTailorCard(
                      name: "Musa's Bespoke Atelier",
                      specialty: 'Modern structural tailoring with hand-stitched details.',
                      rating: '4.9', tag: 'Modern Wedding'),
                    SizedBox(width: 12),
                    _FeaturedTailorCard(
                      name: "Sarah's Silk House",
                      specialty: 'Heritage techniques meet luxury fabrics.',
                      rating: '5.0', tag: 'Heritage Silk'),
                    SizedBox(width: 12),
                    _FeaturedTailorCard(
                      name: "Adeyemi Stitches",
                      specialty: 'Traditional Yoruba attire and fusion wear.',
                      rating: '4.8', tag: 'Agbada Master'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
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
            child: Text(l.cancel),
          ),
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
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(l.logout),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color, iconColor;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label,
    required this.subtitle, required this.color,
    required this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 26),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,    style: AppTheme.titleSmall),
            Text(subtitle, style: AppTheme.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant)),
          ],
        )),
        Icon(Icons.arrow_outward_rounded, size: 14, color: iconColor),
      ]),
    ),
  );
}

class _ActiveOrderCard extends StatelessWidget {
  final OrderModel order;
  final String trackLabel, completeLabel, inProgressLabel;
  final VoidCallback onTap;
  const _ActiveOrderCard({
    required this.order,
    required this.trackLabel,
    required this.completeLabel,
    required this.inProgressLabel,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(
            order.productName ?? (order.isCustom ? 'Custom Order' : 'Order'),
            style: AppTheme.titleSmall,
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(100)),
            child: Text(inProgressLabel, style: AppTheme.labelSmall.copyWith(
                color: AppColors.primary))),
        ]),
        const SizedBox(height: 4),
        Text(order.shopName, style: AppTheme.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: order.progressPercent / 100,
            backgroundColor: AppColors.outlineVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(completeLabel,
              style: AppTheme.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant)),
          Text(trackLabel, style: AppTheme.labelSmall.copyWith(
              color: AppColors.primary)),
        ]),
      ]),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message, retryLabel;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.retryLabel, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.5)),
      child: Column(children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 36),
        const SizedBox(height: 10),
        Text(message, style: AppTheme.bodyMedium.copyWith(color: AppColors.onErrorContainer),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(retryLabel),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ]),
    ),
  );
}

class _EmptyOrdersCard extends StatelessWidget {
  final String noActiveOrders, ordersAppearHere;
  const _EmptyOrdersCard({
    required this.noActiveOrders,
    required this.ordersAppearHere,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5)),
      child: Column(children: [
        const Icon(Icons.receipt_long_outlined,
            color: AppColors.outline, size: 40),
        const SizedBox(height: 12),
        Text(noActiveOrders, style: AppTheme.titleSmall.copyWith(
            color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(ordersAppearHere, style: AppTheme.bodySmall.copyWith(
            color: AppColors.outline)),
      ]),
    ),
  );
}

class _FeaturedTailorCard extends StatelessWidget {
  final String name, specialty, rating, tag;
  const _FeaturedTailorCard({required this.name, required this.specialty,
    required this.rating, required this.tag});
  @override
  Widget build(BuildContext context) => Container(
    width: 220, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.outlineVariant, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(rating, style: AppTheme.labelSmall.copyWith(
            color: AppColors.secondary)),
      ]),
      const SizedBox(height: 8),
      Text(name, style: AppTheme.titleSmall,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Expanded(child: Text(specialty,
          style: AppTheme.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(100)),
        child: Text(tag, style: AppTheme.labelSmall.copyWith(
            color: AppColors.primary))),
    ]),
  );
}
