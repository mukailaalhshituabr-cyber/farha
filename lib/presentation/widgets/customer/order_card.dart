// lib/presentation/widgets/customer/order_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel   order;
  final VoidCallback onTap;
  final bool         showTrackButton;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showTrackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderStatusHelper.color(order.status, context);
    final statusIcon  = OrderStatusHelper.icon(order.status);

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
          // ── Header row ───────────────────────────────────────────
          Row(children: [
            Text(AppFormatters.orderRef(order.referenceNumber),
              style: AppTheme.labelMedium.copyWith(color: AppColors.primary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        statusColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: statusColor.withValues(alpha:0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(OrderStatusHelper.label(order.status),
                  style: AppTheme.labelSmall.copyWith(color: statusColor)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Product name ──────────────────────────────────────────
          Text(order.productName ?? (order.isCustom ? 'Custom Order' : 'Order'),
            style:    AppTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${order.shopName} • ${AppFormatters.date(order.createdAt)}',
            style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),

          const SizedBox(height: 12),

          // ── Progress bar (for active orders) ─────────────────────
          if (order.isActive && !order.isCancelled) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           order.progressPercent / 100,
                backgroundColor: AppColors.outlineVariant,
                valueColor:      AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight:       4,
              ),
            ),
            const SizedBox(height: 4),
            Text('${order.progressPercent}% complete',
              style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 12),
          ],

          // ── Footer row ────────────────────────────────────────────
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppFormatters.currency(order.totalAmount, symbol: order.currency),
                style: AppTheme.titleMedium.copyWith(color: AppColors.primary)),
              if (!order.isFullyPaid)
                Text('Balance: ${AppFormatters.currency(order.balanceDue, symbol: order.currency)}',
                  style: AppTheme.bodySmall.copyWith(color: AppColors.warning)),
            ]),
            const Spacer(),
            if (showTrackButton && order.isActive)
              TextButton.icon(
                onPressed: onTap,
                icon:  const Icon(Icons.track_changes_rounded, size: 16),
                label: const Text('Track'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.outline),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/presentation/widgets/customer/review_card.dart

class ReviewCard extends StatelessWidget {
  final dynamic review; // ReviewModel

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius:          18,
            backgroundColor: AppColors.primaryFixed,
            child: Text(AppFormatters.initials(review.customerName),
              style: AppTheme.labelMedium.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review.customerName, style: AppTheme.titleSmall),
            Text(AppFormatters.relativeTime(review.createdAt),
              style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
          Row(mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) => Icon(
              i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 14,
              color: AppColors.secondary,
            ))),
        ]),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(review.comment!,
            style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ]),
    );
  }
}
