// lib/presentation/screens/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/order_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/farha_confirm_dialog.dart';
import '../../widgets/common/farha_snackbar.dart';
import '../../../routes/app_router.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l         = AppL10n.of(context);
    final isTailor  = ref.watch(authProvider).user?.isTailor ?? false;
    final orderAsync = ref.watch(orderDetailProvider(orderId));

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
        title: Text(l.orders,
            style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
      ),
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorBody(
          message: l.somethingWrong,
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) => order == null
            ? _ErrorBody(
                message: l.noResults,
                retryLabel: l.retry,
                onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
              )
            : _OrderBody(
                order: order,
                isTailor: isTailor,
                l: l,
              ),
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _OrderBody extends ConsumerWidget {
  final OrderModel order;
  final bool       isTailor;
  final AppL10n    l;

  const _OrderBody({
    required this.order,
    required this.isTailor,
    required this.l,
  });

  static const _nextStatus = {
    'pending':   'cutting',
    'confirmed': 'cutting',
    'cutting':   'sewing',
    'sewing':    'ready',
    'ready':     'delivered',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = OrderStatusHelper.color(order.status, context);
    final next        = _nextStatus[order.status];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order ref + status ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppFormatters.orderRef(order.referenceNumber),
                    style: AppTheme.titleMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(AppFormatters.date(order.createdAt),
                    style: AppTheme.bodySmall
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(OrderStatusHelper.label(order.status),
                    style: AppTheme.labelMedium
                        .copyWith(color: statusColor)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Progress stepper ────────────────────────────────────
          if (!order.isCancelled) _ProgressStepper(status: order.status),
          if (!order.isCancelled) const SizedBox(height: 20),

          // ── Product / garment ───────────────────────────────────
          _Section(title: order.isCustom ? 'Custom Order' : 'Product'),
          _InfoCard(children: [
            if (order.productImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: order.productImageUrl!,
                  height: 180, width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      height: 180, color: AppColors.surfaceContainerLow),
                  errorWidget: (_, __, ___) => Container(
                    height: 100, color: AppColors.surfaceContainerLow,
                    child: const Center(child: Icon(
                        Icons.image_outlined, color: AppColors.outline))),
                ),
              ),
            if (order.productImageUrl != null) const SizedBox(height: 12),
            if (order.productName != null)
              _DetailRow(label: 'Item', value: order.productName!),
            if (order.size != null)
              _DetailRow(label: l.selectSize, value: order.size!),
            _DetailRow(
                label: l.quantity, value: '${order.quantity}'),
            _DetailRow(
                label: isTailor ? 'Customer' : l.tailor,
                value: isTailor ? order.customerName
                    : '${order.tailorName} · ${order.shopName}'),
            if (order.estimatedCompletion != null)
              _DetailRow(
                  label: 'Est. Completion',
                  value: order.estimatedCompletion!),
          ]),

          // ── Special instructions ─────────────────────────────────
          if (order.specialInstructions != null &&
              order.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(title: 'Special Instructions'),
            _InfoCard(children: [
              Text(order.specialInstructions!,
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppColors.onSurface)),
            ]),
          ],

          // ── Payment summary ──────────────────────────────────────
          const SizedBox(height: 16),
          _Section(title: l.payment),
          _InfoCard(children: [
            _DetailRow(
                label: l.totalInvoice,
                value: AppFormatters.currency(
                    order.totalAmount, symbol: order.currency),
                bold: true),
            _DetailRow(
                label: l.depositPlan,
                value: AppFormatters.currency(
                    order.depositAmount, symbol: order.currency)),
            _DetailRow(
                label: 'Amount Paid',
                value: AppFormatters.currency(
                    order.paidAmount, symbol: order.currency),
                valueColor: AppColors.success),
            if (!order.isFullyPaid)
              _DetailRow(
                  label: l.payBalance,
                  value: AppFormatters.currency(
                      order.balanceDue, symbol: order.currency),
                  valueColor: AppColors.warning),
          ]),

          // ── Actions ──────────────────────────────────────────────
          const SizedBox(height: 24),
          if (isTailor && next != null)
            _TailorActions(order: order, nextStatus: next, l: l),
          if (!isTailor)
            _CustomerActions(order: order, l: l),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Tailor actions ────────────────────────────────────────────────────────────

class _TailorActions extends ConsumerStatefulWidget {
  final OrderModel order;
  final String     nextStatus;
  final AppL10n    l;

  const _TailorActions({
    required this.order,
    required this.nextStatus,
    required this.l,
  });

  @override
  ConsumerState<_TailorActions> createState() => _TailorActionsState();
}

class _TailorActionsState extends ConsumerState<_TailorActions> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    setState(() => _openingChat = true);
    final api = ref.read(apiClientProvider);
    final res = await api.post(
      ApiConstants.conversations,
      data: {'customer_id': widget.order.customerId},
    );
    if (!mounted) return;
    setState(() => _openingChat = false);

    if (res.success) {
      final convId =
          (res.data as Map<String, dynamic>?)?['conversation_id'] as String? ?? '';
      if (convId.isNotEmpty) {
        context.push('/tailor/chat/$convId');
        return;
      }
    }
    context.push(Routes.tailorChatInbox);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      FilledButton.icon(
        onPressed: () async {
          final label = OrderStatusHelper.label(widget.nextStatus);
          final confirmed = await FarhaConfirmDialog.show(
            context,
            title: 'Update Order Status?',
            body:  'Move this order to "$label"? This action cannot be undone.',
            confirmLabel: 'Confirm',
          );
          if (!confirmed || !context.mounted) return;
          final ok = await ref
              .read(orderProvider.notifier)
              .updateStatus(widget.order.id, widget.nextStatus);
          if (!context.mounted) return;
          if (ok) {
            FarhaSnackbar.success(context, 'Order updated to $label');
            ref.invalidate(orderDetailProvider(widget.order.id));
          } else {
            FarhaSnackbar.error(context, 'Could not update order status.');
          }
        },
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: Text('Move to ${OrderStatusHelper.label(widget.nextStatus)}'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _openingChat ? null : _openChat,
        icon: _openingChat
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))
            : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: Text(_openingChat ? 'Opening...' : 'Message ${widget.order.customerName}'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ]);
  }
}

// ── Customer actions ──────────────────────────────────────────────────────────

class _CustomerActions extends ConsumerWidget {
  final OrderModel order;
  final AppL10n    l;

  const _CustomerActions({required this.order, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      if (!order.isFullyPaid && order.isActive)
        FilledButton.icon(
          onPressed: () => context.push(
              '/customer/order/pay-balance/${order.id}'),
          icon: const Icon(Icons.payment_rounded, size: 18),
          label: Text(l.payBalance),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      if (!order.isFullyPaid && order.isActive)
        const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => context.push(
            Routes.orderTracking.replaceFirst(':id', order.id)),
        icon: const Icon(Icons.location_on_outlined, size: 18),
        label: Text(l.trackOrder),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
      if (order.isActive) ...[
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => _showCancelDialog(context, ref),
          icon: const Icon(Icons.cancel_outlined,
              size: 18, color: AppColors.error),
          label: Text(l.cancelOrder,
              style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ]);
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancelOrder),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Please let us know why you\'re cancelling.',
              style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Reason (optional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(orderProvider.notifier)
                  .cancelOrder(order.id, reasonCtrl.text.trim());
              if (!context.mounted) return;
              if (ok) {
                FarhaSnackbar.success(context, 'Order cancelled.');
                ref.invalidate(orderDetailProvider(order.id));
              } else {
                FarhaSnackbar.error(context, 'Could not cancel order.');
              }
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}

// ── Progress stepper ──────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final String status;
  const _ProgressStepper({required this.status});

  static const _steps = [
    'pending', 'confirmed', 'cutting', 'sewing', 'ready', 'delivered'
  ];
  static const _labels = [
    'Pending', 'Confirmed', 'Cutting', 'Sewing', 'Ready', 'Delivered'
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(status);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIdx = i ~/ 2;
          final done = stepIdx < current;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.primary : AppColors.outlineVariant,
            ),
          );
        }
        // Step dot
        final stepIdx = i ~/ 2;
        final done    = stepIdx <= current;
        final active  = stepIdx == current;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: active ? 28 : 22,
            height: active ? 28 : 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.primary : AppColors.surfaceContainerLow,
              border: Border.all(
                color: done ? AppColors.primary : AppColors.outlineVariant,
                width: active ? 3 : 1.5,
              ),
            ),
            child: done
                ? Icon(Icons.check_rounded,
                    size: active ? 14 : 12, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 4),
          Text(_labels[stepIdx],
              style: AppTheme.labelSmall.copyWith(
                color: done ? AppColors.primary : AppColors.onSurfaceVariant,
                fontSize: 9,
              )),
        ]);
      }),
    );
  }
}

// ── Re-usable sub-widgets ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant, letterSpacing: 1.1)),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.outlineVariant, width: 0.5),
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children),
  );
}

class _DetailRow extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    bold;
  final Color?  valueColor;
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: AppTheme.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor,
              )),
        ),
      ],
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  final String       message;
  final String       retryLabel;
  final VoidCallback onRetry;
  const _ErrorBody({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded,
          color: AppColors.outline, size: 48),
      const SizedBox(height: 12),
      Text(message,
          style: AppTheme.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 16),
      FilledButton(onPressed: onRetry, child: Text(retryLabel)),
    ]),
  );
}
