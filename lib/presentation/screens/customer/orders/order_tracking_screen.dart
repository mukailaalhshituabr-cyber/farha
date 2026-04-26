// lib/presentation/screens/customer/orders/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../../routes/app_router.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _openingChat = false;

  Future<void> _openChat(String tailorId) async {
    setState(() => _openingChat = true);
    final api = ref.read(apiClientProvider);
    final res = await api.post(
      ApiConstants.conversations,
      data: {'tailor_id': tailorId},
    );
    if (!mounted) return;
    setState(() => _openingChat = false);

    if (res.success) {
      final convId =
          (res.data as Map<String, dynamic>?)?['conversation_id'] as String? ??
              '';
      if (convId.isNotEmpty) {
        context.push(Routes.chatScreen.replaceFirst(':id', convId));
        return;
      }
    }
    // Fallback: open inbox so the user can find the conversation manually
    context.push(Routes.chatInbox);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Track Order',
          style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(
            color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Could not load order.')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }

          // Status values must match what the DB stores.
          // 'pending' = order just placed; displayed as "Ordered".
          const stages = [
            ('pending',   'Ordered',   Icons.inventory_2_outlined),
            ('confirmed', 'Confirmed', Icons.check_circle_outline_rounded),
            ('cutting',   'Cutting',   Icons.content_cut_rounded),
            ('sewing',    'Sewing',    Icons.checkroom_outlined),
            ('ready',     'Ready',     Icons.auto_awesome_outlined),
            ('delivered', 'Delivered', Icons.local_shipping_outlined),
          ];

          final currentIndex =
              stages.indexWhere((s) => s.$1 == order.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Order reference card ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppFormatters.orderRef(order.referenceNumber),
                      style: AppTheme.titleSmall.copyWith(
                          color: AppColors.primary)),
                    Text('Placed on ${AppFormatters.date(order.createdAt)}',
                      style: AppTheme.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      order.isDelivered ? 'Delivered'
                          : order.isCancelled ? 'Cancelled'
                          : 'In Progress',
                      style: AppTheme.labelSmall.copyWith(
                          color: AppColors.onPrimary)),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Tailor info ──────────────────────────────────────
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryFixed,
                  child: Text(AppFormatters.initials(order.tailorName),
                    style: AppTheme.labelMedium.copyWith(
                        color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.shopName, style: AppTheme.titleSmall),
                  Text(order.tailorName,
                    style: AppTheme.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant)),
                ]),
              ]),

              const SizedBox(height: 24),

              // ── Progress stepper ─────────────────────────────────
              Text('Order Progress',
                style: AppTheme.titleMedium.copyWith(
                    fontFamily: 'PlusJakartaSans')),
              const SizedBox(height: 16),

              ...List.generate(stages.length, (i) {
                final stage     = stages[i];
                final isDone    = currentIndex >= 0 && i <= currentIndex;
                final isCurrent = i == currentIndex;
                final isLast    = i == stages.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon column
                    Column(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.primary
                              : AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(
                                  color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Icon(stage.$3, size: 18,
                          color: isDone
                              ? AppColors.onPrimary
                              : AppColors.outline),
                      ),
                      if (!isLast)
                        Container(
                          width: 2, height: 48,
                          color: isDone
                              ? AppColors.primary
                              : AppColors.outlineVariant),
                    ]),
                    const SizedBox(width: 16),
                    // Label
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stage.$2,
                            style: AppTheme.titleSmall.copyWith(
                              color: isDone
                                  ? AppColors.onBackground
                                  : AppColors.outline,
                              fontWeight: isCurrent
                                  ? FontWeight.w600 : FontWeight.w400,
                            )),
                          if (isCurrent)
                            Text('In progress...',
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.primary)),
                          if (isDone && !isCurrent)
                            Text('Completed',
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.success)),
                        ],
                      ),
                    )),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // ── Order summary ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.outlineVariant, width: 0.5),
                ),
                child: Column(children: [
                  Text(order.productName ?? 'Custom Order',
                    style: AppTheme.titleSmall),
                  if (order.size != null)
                    Text(order.size!, style: AppTheme.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant)),
                  const Divider(height: 20),
                  _SummaryRow('Subtotal',
                      AppFormatters.currency(order.totalAmount,
                          symbol: order.currency)),
                  _SummaryRow('Deposit Paid',
                      AppFormatters.currency(order.depositAmount,
                          symbol: order.currency)),
                  if (!order.isFullyPaid)
                    _SummaryRow('Balance Due',
                        AppFormatters.currency(order.balanceDue,
                            symbol: order.currency),
                        valueColor: AppColors.warning),
                ]),
              ),

              // ── Tailor location ──────────────────────────────────
              if (order.shopLocation != null &&
                  order.shopLocation!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _LocationCard(order: order),
              ],

              const SizedBox(height: 20),

              // ── Action buttons ───────────────────────────────────
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _openingChat
                      ? null
                      : () => _openChat(order.tailorId),
                  icon: _openingChat
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary))
                      : const Icon(
                          Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Message Tailor'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100))),
                )),
                if (!order.isFullyPaid) ...[
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => context.push(
                        '/customer/order/pay-balance/${order.id}'),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('Pay Balance'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100))),
                  )),
                ],
              ]),

              const SizedBox(height: 32),
            ]),
          );
        },
      ),
    );
  }
}

// ── Location card ─────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final OrderModel order;
  const _LocationCard({required this.order});

  Future<void> _openMap(BuildContext context) async {
    final location = order.shopLocation!;
    Uri uri;

    if (order.latitude != null && order.longitude != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1'
          '&query=${order.latitude},${order.longitude}');
    } else {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1'
          '&query=${Uri.encodeComponent(location)}');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.outlineVariant, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: const BoxDecoration(
          color: AppColors.primaryFixed, shape: BoxShape.circle),
        child: const Icon(Icons.storefront_rounded,
            color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.shopName,
              style: AppTheme.titleSmall
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(order.shopLocation!,
              style: AppTheme.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      )),
      const SizedBox(width: 8),
      OutlinedButton.icon(
        onPressed: () => _openMap(context),
        icon: const Icon(Icons.directions_rounded, size: 16),
        label: const Text('Directions'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100)),
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
    ]),
  );
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant)),
        Text(value, style: AppTheme.labelMedium.copyWith(
            color: valueColor ?? AppColors.onBackground)),
      ],
    ),
  );
}
