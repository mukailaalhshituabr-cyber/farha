// lib/presentation/screens/customer/orders/order_success_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/app_router.dart';

class OrderSuccessScreen extends StatelessWidget {
  /// List of order reference numbers that were just placed.
  final List<String> references;

  const OrderSuccessScreen({super.key, required this.references});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => context.go(Routes.customerDashboard),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // ── Success animation ────────────────────────────────
                Container(
                  width: 120, height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 72),
                ),

                const SizedBox(height: 28),

                Text('Order Placed!',
                    style: AppTheme.headlineMedium.copyWith(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w700)),

                const SizedBox(height: 10),

                Text(
                  references.length == 1
                      ? 'Your order has been sent to the tailor.\nThey will confirm it shortly.'
                      : 'Your ${references.length} orders have been sent to the tailors.\nThey will confirm shortly.',
                  style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // ── Order references ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.outlineVariant, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reference Number${references.length > 1 ? 's' : ''}',
                          style: AppTheme.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 10),
                      ...references.map((ref) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          const Icon(Icons.receipt_long_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(ref,
                              style: AppTheme.titleSmall.copyWith(
                                  color: AppColors.primary,
                                  fontFamily: 'PlusJakartaSans',
                                  letterSpacing: 0.5)),
                        ]),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Info about deposit
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'A 30% deposit has been reserved. '
                        'Pay the balance when you collect or receive your order.',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurface),
                      ),
                    ),
                  ]),
                ),

                const Spacer(),

                // ── CTAs ─────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: () => context.go(Routes.orderHistory),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('View My Orders'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () => context.go(Routes.productListing),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Continue Shopping'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
