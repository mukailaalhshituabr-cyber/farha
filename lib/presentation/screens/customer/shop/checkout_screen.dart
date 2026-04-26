// lib/presentation/screens/customer/shop/checkout_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/cart_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';
import '../../../../routes/app_router.dart';

// ── Payment methods ────────────────────────────────────────────────────────────

enum _PayMethod { mtnMomo, telecel, orangeMoney, myNita, amana, cashOnPickup }

extension _PayMethodX on _PayMethod {
  String get label => switch (this) {
    _PayMethod.mtnMomo      => 'MTN Mobile Money',
    _PayMethod.telecel      => 'Telecel Cash',
    _PayMethod.orangeMoney  => 'Orange Money',
    _PayMethod.myNita       => 'MyNita',
    _PayMethod.amana        => 'Amana',
    _PayMethod.cashOnPickup => 'Cash on Pickup',
  };

  IconData get icon => switch (this) {
    _PayMethod.mtnMomo      => Icons.signal_cellular_alt_rounded,
    _PayMethod.telecel      => Icons.phone_android_rounded,
    _PayMethod.orangeMoney  => Icons.circle_outlined,
    _PayMethod.myNita       => Icons.account_balance_wallet_rounded,
    _PayMethod.amana        => Icons.savings_rounded,
    _PayMethod.cashOnPickup => Icons.storefront_outlined,
  };

  bool get needsPhone => this != _PayMethod.cashOnPickup;

  String get apiValue => switch (this) {
    _PayMethod.mtnMomo      => 'mtn_momo',
    _PayMethod.telecel      => 'telecel',
    _PayMethod.orangeMoney  => 'orange_money',
    _PayMethod.myNita       => 'mynita',
    _PayMethod.amana        => 'amana',
    _PayMethod.cashOnPickup => 'cash_on_pickup',
  };
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItemModel> cartItems;
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  _PayMethod _method  = _PayMethod.mtnMomo;
  final _phoneCtrl    = TextEditingController();
  bool _placing       = false;

  double get _total   => widget.cartItems.fold(0, (s, i) => s + i.subtotal);
  // 30% deposit required; rest on pickup
  double get _deposit => _total * 0.30;
  String get _currency => widget.cartItems.isNotEmpty
      ? widget.cartItems.first.currency : 'CFA';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_method.needsPhone && _phoneCtrl.text.trim().isEmpty) {
      FarhaSnackbar.error(context, 'Please enter your mobile money number.');
      return;
    }

    setState(() => _placing = true);

    final repo = ref.read(orderRepositoryProvider);
    final api  = ref.read(apiClientProvider);
    final refs = <String>[];

    for (final item in widget.cartItems) {
      final deposit = double.parse(
          (item.subtotal * 0.30).toStringAsFixed(2));

      final orderRes = await repo.createOrder({
        'tailor_id':      item.tailorId,
        'product_id':     item.productId,
        'order_type':     'ready_made',
        'quantity':       item.quantity,
        'total_amount':   item.subtotal,
        'deposit_amount': deposit,
        'currency':       item.currency,
        if (item.size != null) 'size': item.size,
      });

      if (!orderRes.success || orderRes.data == null) continue;

      final orderId = orderRes.data['order_id'] as String? ?? '';
      final ref_    = orderRes.data['reference_number'] as String? ?? '';

      // Record the deposit payment immediately
      await api.post(ApiConstants.paymentInitiate, data: {
        'order_id':       orderId,
        'amount':         deposit,
        'payment_method': _method.apiValue,
        if (_method.needsPhone) 'phone': _phoneCtrl.text.trim(),
      });

      if (ref_.isNotEmpty) refs.add(ref_);
    }

    if (!mounted) return;
    setState(() => _placing = false);

    if (refs.isEmpty) {
      FarhaSnackbar.error(context, 'Could not place order. Please try again.');
      return;
    }

    // Clear cart and navigate to success
    ref.read(cartProvider.notifier).clear();
    ref.read(orderProvider.notifier).refresh();

    if (!mounted) return;
    context.go(Routes.orderSuccess, extra: refs);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Checkout',
            style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Order summary ──────────────────────────────────────────
          _SectionLabel('Order Summary'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant, width: 0.5),
            ),
            child: Column(
              children: [
                ...widget.cartItems.map((item) => _ItemRow(item: item)),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _SummaryRow('Subtotal',
                        AppFormatters.currency(_total, symbol: _currency)),
                    _SummaryRow('Deposit (30%)',
                        AppFormatters.currency(_deposit, symbol: _currency),
                        hint: 'Pay now'),
                    _SummaryRow('Balance (70%)',
                        AppFormatters.currency(_total - _deposit, symbol: _currency),
                        hint: 'On pickup/delivery',
                        valueColor: AppColors.onSurfaceVariant),
                  ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Payment method ─────────────────────────────────────────
          _SectionLabel('Payment Method'),
          ...(_PayMethod.values.map((m) => _PayMethodTile(
            method: m,
            selected: _method == m,
            onTap: () => setState(() => _method = m),
          ))),

          // ── Phone number (mobile money) ────────────────────────────
          if (_method.needsPhone) ...[
            const SizedBox(height: 16),
            _SectionLabel('Mobile Money Number'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. +221 77 000 00 00',
                hintStyle: AppTheme.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Deposit info box ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You pay a 30% deposit now '
                  '(${AppFormatters.currency(_deposit, symbol: _currency)}). '
                  'The remaining balance is due on pickup or delivery.',
                  style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: _placing ? null : _placeOrder,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _placing
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(
                    'Place Order · ${AppFormatters.currency(_deposit, symbol: _currency)}',
                    style: AppTheme.labelLarge),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant, letterSpacing: 1.1)),
  );
}

class _ItemRow extends StatelessWidget {
  final CartItemModel item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.productImageUrl != null
            ? CachedNetworkImage(
                imageUrl: item.productImageUrl!,
                width: 52, height: 52, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                    width: 52, height: 52, color: AppColors.surfaceContainerLow,
                    child: const Icon(Icons.image_outlined, color: AppColors.outline)),
              )
            : Container(
                width: 52, height: 52, color: AppColors.surfaceContainerLow,
                child: const Icon(Icons.image_outlined, color: AppColors.outline)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.productName,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        if (item.size != null)
          Text('Size: ${item.size}',
              style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
        Text('Qty: ${item.quantity}',
            style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
      ])),
      Text(AppFormatters.currency(item.subtotal, symbol: item.currency),
          style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final String? hint;
  final Color? valueColor;
  const _SummaryRow(this.label, this.value, {this.hint, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Row(children: [
        Text(label, style: AppTheme.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant)),
        if (hint != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(hint!, style: AppTheme.labelSmall.copyWith(
                color: AppColors.primary, fontSize: 9)),
          ),
        ],
      ])),
      Text(value, style: AppTheme.labelMedium.copyWith(
          color: valueColor ?? AppColors.onBackground)),
    ]),
  );
}

class _PayMethodTile extends StatelessWidget {
  final _PayMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PayMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryFixed : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
          width: selected ? 1.5 : 0.5,
        ),
      ),
      child: Row(children: [
        Icon(method.icon,
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(method.label,
            style: AppTheme.bodyMedium.copyWith(
              color: selected ? AppColors.primary : AppColors.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ))),
        if (selected)
          const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 20),
      ]),
    ),
  );
}
