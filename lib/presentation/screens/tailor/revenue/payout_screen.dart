// lib/presentation/screens/tailor/revenue/payout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';

class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  String _method = 'mtn_momo';
  bool   _submitting = false;

  static const _methods = [
    {'value': 'mtn_momo',     'label': 'MTN Mobile Money', 'icon': Icons.signal_cellular_alt_rounded},
    {'value': 'telecel',      'label': 'Telecel Cash',      'icon': Icons.phone_android_rounded},
    {'value': 'orange_money', 'label': 'Orange Money',      'icon': Icons.circle_outlined},
    {'value': 'mynita',       'label': 'MyNita',            'icon': Icons.account_balance_wallet_rounded},
    {'value': 'amana',        'label': 'Amana',             'icon': Icons.savings_rounded},
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final api = ref.read(apiClientProvider);
    final res = await api.post(ApiConstants.payout, data: {
      'amount':        double.tryParse(_amountCtrl.text.trim()) ?? 0,
      'payout_method': _method,
      'account':       _accountCtrl.text.trim(),
    });
    setState(() => _submitting = false);
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context,
          'Payout request submitted. Processing takes 1–3 business days.');
      Navigator.pop(context);
    } else {
      FarhaSnackbar.error(context,
          res.message.isNotEmpty ? res.message : 'Payout request failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/tailor/dashboard'),
        ),
        title: Text(l.requestPayout,
            style: AppTheme.titleLarge.copyWith(
                fontFamily: 'PlusJakartaSans')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Info card ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payouts are processed within 1–3 business days.',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Amount ──────────────────────────────────────────────
            Text('Amount (CFA)',
                style: AppTheme.labelMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money_rounded,
                    color: AppColors.onSurfaceVariant, size: 20),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.error),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l.fieldRequired;
                }
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Payout method ────────────────────────────────────────
            Text('Payout Method',
                style: AppTheme.labelMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 10),
            ..._methods.map((m) {
              final selected = _method == m['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _method = m['value'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryFixed
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(children: [
                      Icon(m['icon'] as IconData,
                          color: selected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          size: 22),
                      const SizedBox(width: 12),
                      Text(m['label'] as String,
                          style: AppTheme.bodyMedium.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.onSurface,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 20),
                    ]),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // ── Account number ───────────────────────────────────────
            Text('Account / Phone Number',
                style: AppTheme.labelMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+1 234 567 8900',
                prefixIcon: const Icon(Icons.numbers_rounded,
                    color: AppColors.onSurfaceVariant, size: 20),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.error),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldRequired : null,
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(l.requestPayout,
                      style: AppTheme.labelLarge),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
