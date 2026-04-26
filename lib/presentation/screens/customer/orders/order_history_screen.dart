// lib/presentation/screens/customer/orders/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _State();
}

class _State extends ConsumerState<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Order History',
          style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor:        AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor:    AppColors.primary,
          labelStyle:        AppTheme.labelMedium,
          unselectedLabelStyle: AppTheme.labelMedium,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
          onTap: (i) {
            final filters = [null, 'active', 'delivered', 'cancelled'];
            ref.read(orderProvider.notifier).filterByStatus(filters[i]);
          },
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
          : state.items.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppColors.outline, size: 48),
                    const SizedBox(height: 12),
                    Text('No orders found',
                      style: AppTheme.titleSmall.copyWith(
                          color: AppColors.onSurfaceVariant)),
                  ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.read(orderProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _OrderCard(
                      order: state.items[i],
                      onTap: () {
                        final o = state.items[i];
                        if (o.isActive) {
                          context.push('/customer/order/track/${o.id}');
                        } else {
                          context.push('/customer/order/${o.id}');
                        }
                      },
                    ),
                  ),
                ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 2),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderStatusHelper.color(order.status, context);
    final statusLabel = OrderStatusHelper.label(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Reference + status
          Row(children: [
            Text(AppFormatters.orderRef(order.referenceNumber),
              style: AppTheme.labelMedium.copyWith(color: AppColors.primary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: statusColor.withValues(alpha:0.3)),
              ),
              child: Text(statusLabel,
                style: AppTheme.labelSmall.copyWith(color: statusColor)),
            ),
          ]),
          const SizedBox(height: 6),

          // Product name
          Text(order.productName ?? (order.isCustom ? 'Custom Order' : 'Order'),
            style: AppTheme.titleSmall,
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${order.shopName} • ${AppFormatters.date(order.createdAt)}',
            style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),

          // Progress for active
          if (order.isActive) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: order.progressPercent / 100,
                backgroundColor: AppColors.outlineVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text('${order.progressPercent}% complete',
              style: AppTheme.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant)),
          ],

          const SizedBox(height: 10),

          // Amount + action
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppFormatters.currency(order.totalAmount,
                  symbol: order.currency),
                style: AppTheme.titleSmall.copyWith(color: AppColors.primary)),
              if (!order.isFullyPaid && order.isActive)
                Text('Balance: ${AppFormatters.currency(
                    order.balanceDue, symbol: order.currency)}',
                  style: AppTheme.bodySmall.copyWith(color: AppColors.warning)),
            ]),
            const Spacer(),
            Row(children: [
              if (order.isActive)
                Text('Track Order',
                  style: AppTheme.labelSmall.copyWith(color: AppColors.primary))
              else if (order.isDelivered)
                Text('View Details',
                  style: AppTheme.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant))
              else
                Text('View Reason',
                  style: AppTheme.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: AppColors.outline),
            ]),
          ]),
        ]),
      ),
    );
  }
}
