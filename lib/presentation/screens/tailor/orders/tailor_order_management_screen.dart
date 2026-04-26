// lib/presentation/screens/tailor/orders/tailor_order_management_screen.dart
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
import '../../../widgets/common/farha_snackbar.dart';

class TailorOrderManagementScreen extends ConsumerStatefulWidget {
  const TailorOrderManagementScreen({super.key});

  @override
  ConsumerState<TailorOrderManagementScreen> createState() => _State();
}

class _State extends ConsumerState<TailorOrderManagementScreen> {
  String? _statusFilter;

  static const _filters = [
    {'label': 'All Orders', 'value': null},
    {'label': 'Pending',    'value': 'pending'},
    {'label': 'Cutting',    'value': 'cutting'},
    {'label': 'Sewing',     'value': 'sewing'},
    {'label': 'Ready',      'value': 'ready'},
    {'label': 'Delivered',  'value': 'delivered'},
  ];

  static const _nextStatus = {
    'pending':   'cutting',
    'confirmed': 'cutting',
    'cutting':   'sewing',
    'sewing':    'ready',
    'ready':     'delivered',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final filtered = _statusFilter == null
        ? state.items
        : state.items.where((o) => o.status == _statusFilter).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => context.go('/tailor/dashboard'),
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/tailor/dashboard'),
        ),
        title: Text('Order Management',
          style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(children: [
        // ── Status filter chips ───────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: _filters.map((f) {
              final selected = _statusFilter == f['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f['label'] as String),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _statusFilter = f['value']);
                  },
                  backgroundColor:  AppColors.surfaceContainerLow,
                  selectedColor:    AppColors.primaryFixed,
                  labelStyle: AppTheme.labelMedium.copyWith(
                    color: selected ? AppColors.primary
                        : AppColors.onSurfaceVariant),
                  side: BorderSide(
                    color: selected ? AppColors.primary
                        : AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),

        // ── Order list ────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : filtered.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined,
                            color: AppColors.outline, size: 48),
                        const SizedBox(height: 12),
                        Text('No orders found',
                          style: AppTheme.titleSmall.copyWith(
                              color: AppColors.onSurfaceVariant)),
                      ]))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async =>
                          ref.read(orderProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final order = filtered[i];
                          final next  = _nextStatus[order.status];
                          return _OrderCard(
                            order: order,
                            onTap: () => context.push(
                                '/tailor/order/${order.id}'),
                            onUpdateStatus: next != null
                                ? () async {
                                    final ok = await ref
                                        .read(orderProvider.notifier)
                                        .updateStatus(order.id, next);
                                    if (!context.mounted) return;
                                    if (ok) {
                                      FarhaSnackbar.success(context,
                                          'Order updated to '
                                          '${OrderStatusHelper.label(next)}');
                                    } else {
                                      FarhaSnackbar.error(context,
                                          'Could not update order status.');
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
        ),
      ]),
      bottomNavigationBar: const TailorBottomNav(currentIndex: 1),
    ),   // Scaffold
    );   // PopScope
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onUpdateStatus;

  const _OrderCard({required this.order, required this.onTap,
    this.onUpdateStatus});

  static const _nextStatus = {
    'pending':   'cutting',
    'confirmed': 'cutting',
    'cutting':   'sewing',
    'sewing':    'ready',
    'ready':     'delivered',
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderStatusHelper.color(order.status, context);
    final next        = _nextStatus[order.status];

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
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.customerName,
                style: AppTheme.titleSmall,
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${AppFormatters.orderRef(order.referenceNumber)} • '
                  '${AppFormatters.date(order.createdAt)}',
                style: AppTheme.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant)),
              if (order.productName != null)
                Text(order.productName!,
                  style: AppTheme.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(OrderStatusHelper.label(order.status),
                style: AppTheme.labelSmall.copyWith(color: statusColor)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total: ${AppFormatters.currency(order.totalAmount,
                  symbol: order.currency)}',
                style: AppTheme.labelMedium),
              Text('Paid: ${AppFormatters.currency(order.paidAmount,
                  symbol: order.currency)}',
                style: AppTheme.bodySmall.copyWith(
                  color: order.isFullyPaid
                      ? AppColors.success : AppColors.warning)),
              if (!order.isFullyPaid)
                Text('Balance: ${AppFormatters.currency(order.balanceDue,
                    symbol: order.currency)}',
                  style: AppTheme.bodySmall.copyWith(color: AppColors.warning)),
            ]),
            const Spacer(),
            if (next != null && onUpdateStatus != null)
              ElevatedButton(
                onPressed: onUpdateStatus,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: AppTheme.labelSmall,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                child: Text('→ ${OrderStatusHelper.label(next)}'),
              ),
          ]),
        ]),
      ),
    );
  }
}
