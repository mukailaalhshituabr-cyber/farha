// lib/presentation/widgets/tailor/order_management_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/order_model.dart';

class TailorOrderCard extends StatelessWidget {
  final OrderModel   order;
  final VoidCallback onTap;
  final void Function(String status)? onUpdateStatus;

  const TailorOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onUpdateStatus,
  });

  static const _nextStatus = {
    'pending':   'confirmed',
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
          color:        AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.customerName,
                style: AppTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${AppFormatters.orderRef(order.referenceNumber)} • ${order.productName ?? "Custom"}',
                style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        statusColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(OrderStatusHelper.label(order.status),
                style: AppTheme.labelSmall.copyWith(color: statusColor)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total: ${AppFormatters.currency(order.totalAmount, symbol: order.currency)}',
                style: AppTheme.labelMedium),
              Text('Paid: ${AppFormatters.currency(order.paidAmount, symbol: order.currency)}',
                style: AppTheme.bodySmall.copyWith(
                  color: order.isFullyPaid ? AppColors.success : AppColors.warning)),
              if (!order.isFullyPaid)
                Text('Due: ${AppFormatters.currency(order.balanceDue, symbol: order.currency)}',
                  style: AppTheme.bodySmall.copyWith(color: AppColors.warning)),
            ]),
            const Spacer(),
            if (next != null && onUpdateStatus != null)
              ElevatedButton.icon(
                onPressed: () => onUpdateStatus!(next),
                icon:  const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('→ ${OrderStatusHelper.label(next)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize:     const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: AppTheme.labelSmall,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/presentation/widgets/tailor/tailor_product_card.dart

class TailorProductCard extends StatelessWidget {
  final dynamic      product; // ProductModel
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TailorProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stockQuantity == 0;
    final isDraft      = product.isDraft;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Row(children: [
        // Image placeholder / thumbnail
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color:        AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.dry_cleaning_rounded,
              color: AppColors.outline, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name,
            style: AppTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(AppFormatters.currency(product.basePrice.toDouble(), symbol: product.currency),
            style: AppTheme.labelMedium.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Row(children: [
            if (isDraft)
              _StatusBadge(label: 'Draft', color: AppColors.outline)
            else if (isOutOfStock)
              _StatusBadge(label: 'Out of Stock', color: AppColors.error)
            else
              _StatusBadge(label: 'In Stock (${product.stockQuantity})', color: AppColors.success),
          ]),
        ])),
        PopupMenuButton<String>(
          onSelected: (v) { if (v == 'edit') {
            onEdit();
          } else {
            onDelete();
          } },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',   child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete',
                style: TextStyle(color: AppColors.error))),
          ],
          child: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant),
        ),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withValues(alpha:0.1),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label,
      style: AppTheme.labelSmall.copyWith(color: color)),
  );
}
