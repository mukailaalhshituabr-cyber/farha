// lib/presentation/screens/customer/orders/pay_balance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';

// ── Payment methods ─────────────────────────────────────────────────────────
enum _PayMethod { mtnMomo, telecel, orangeMoney, myNita, amana }

extension _PayMethodX on _PayMethod {
  String get label => switch (this) {
    _PayMethod.mtnMomo     => 'MTN Mobile Money',
    _PayMethod.telecel     => 'Telecel Cash',
    _PayMethod.orangeMoney => 'Orange Money',
    _PayMethod.myNita      => 'MyNita',
    _PayMethod.amana       => 'Amana',
  };
  String get value => switch (this) {
    _PayMethod.mtnMomo     => 'mtn_momo',
    _PayMethod.telecel     => 'telecel',
    _PayMethod.orangeMoney => 'orange_money',
    _PayMethod.myNita      => 'mynita',
    _PayMethod.amana       => 'amana',
  };
  IconData get icon => switch (this) {
    _PayMethod.mtnMomo     => Icons.signal_cellular_alt_rounded,
    _PayMethod.telecel     => Icons.phone_android_rounded,
    _PayMethod.orangeMoney => Icons.circle_outlined,
    _PayMethod.myNita      => Icons.account_balance_wallet_rounded,
    _PayMethod.amana       => Icons.savings_rounded,
  };
}

// ── Screen ──────────────────────────────────────────────────────────────────
class PayBalanceScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PayBalanceScreen({super.key, required this.orderId});

  @override
  ConsumerState<PayBalanceScreen> createState() => _PayBalanceScreenState();
}

class _PayBalanceScreenState extends ConsumerState<PayBalanceScreen> {
  final _phoneCtrl = TextEditingController();
  _PayMethod _method = _PayMethod.mtnMomo;
  bool _paying = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay(OrderModel order) async {
    if (_phoneCtrl.text.trim().isEmpty) {
      FarhaSnackbar.error(context, 'Please enter your mobile money number.');
      return;
    }
    setState(() => _paying = true);
    final api = ref.read(apiClientProvider);
    final res = await api.post(ApiConstants.paymentInitiate, data: {
      'order_id':       order.id,
      'amount':         order.balanceDue,
      'payment_method': _method.value,
      'phone':          _phoneCtrl.text.trim(),
    });
    setState(() => _paying = false);
    if (!mounted) return;
    if (res.success) {
      ref.read(orderProvider.notifier).refresh();
      FarhaSnackbar.success(context, 'Balance paid successfully!');
      context.pop();
    } else {
      FarhaSnackbar.error(context,
          res.message.isNotEmpty ? res.message : 'Payment failed. Please try again.');
    }
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Pay Balance',
            style: AppTheme.titleLarge
                .copyWith(fontFamily: 'PlusJakartaSans')),
      ),
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.outline, size: 48),
            const SizedBox(height: 12),
            Text('Could not load order',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(orderDetailProvider(widget.orderId)),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (order) {
          if (order == null) {
            return Center(
                child: Text('Order not found.',
                    style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant)));
          }
          if (order.isFullyPaid) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 56),
                const SizedBox(height: 12),
                Text('Already fully paid!',
                    style: AppTheme.titleMedium
                        .copyWith(color: AppColors.success)),
              ]),
            );
          }
          return _buildForm(order);
        },
      ),
    );
  }

  Widget _buildForm(OrderModel order) {
    final currency = order.currency;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Balance summary card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
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
              Text('Order #${order.referenceNumber}',
                  style: AppTheme.bodySmall
                      .copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Balance Due',
                  style: AppTheme.bodyMedium
                      .copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                AppFormatters.currency(order.balanceDue, symbol: currency),
                style: AppTheme.displayMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _StatPair(
                  label: 'Total',
                  value: AppFormatters.currency(
                      order.totalAmount, symbol: currency),
                ),
                const SizedBox(width: 24),
                _StatPair(
                  label: 'Paid',
                  value: AppFormatters.currency(
                      order.paidAmount, symbol: currency),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Payment method ────────────────────────────────────────────
        Text('PAYMENT METHOD',
            style: AppTheme.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant, letterSpacing: 1.1)),
        const SizedBox(height: 10),
        ..._PayMethod.values.map((m) {
          final sel = _method == m;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _method = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primaryFixed
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    width: sel ? 1.5 : 0.5,
                  ),
                ),
                child: Row(children: [
                  Icon(m.icon,
                      color: sel
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(m.label,
                        style: AppTheme.bodyMedium.copyWith(
                          color: sel
                              ? AppColors.primary
                              : AppColors.onSurface,
                          fontWeight: sel
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                  ),
                  if (sel)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // ── Phone number ──────────────────────────────────────────────
        Text('MOBILE MONEY NUMBER',
            style: AppTheme.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'e.g. +227 90 00 00 00',
            hintStyle: AppTheme.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 32),

        FilledButton(
          onPressed: _paying ? null : () => _pay(order),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _paying
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(
                  'Pay ${AppFormatters.currency(order.balanceDue, symbol: currency)}',
                  style: AppTheme.labelLarge),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatPair extends StatelessWidget {
  final String label, value;
  const _StatPair({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: AppTheme.labelSmall.copyWith(color: Colors.white60)),
      Text(value,
          style: AppTheme.bodySmall.copyWith(
              color: Colors.white, fontWeight: FontWeight.w600)),
    ],
  );
}
