// lib/presentation/screens/admin/admin_payments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';
import 'admin_shell.dart';

final _adminPaymentsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, status) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiConstants.adminPayments,
      params: {'status': status, 'limit': 50});
  if (!res.success) throw Exception(res.message);
  return res.data as Map<String, dynamic>;
});

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});
  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _status = '';

  Future<void> _refund(String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A1010),
        title: const Text('Confirm Refund', style: TextStyle(color: Colors.white)),
        content: const Text('This will refund the payment and reverse the order balance.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await ref.read(apiClientProvider).post(
        ApiConstants.adminPayments, data: {'payment_id': paymentId, 'action': 'refund'});
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context, 'Payment refunded.');
      ref.invalidate(_adminPaymentsProvider(_status));
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(_adminPaymentsProvider(_status));

    return AdminShell(
      child: Column(children: [
        Container(
          color: const Color(0xFF1A0A0A),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Payments', style: AppTheme.headlineMedium.copyWith(
                color: Colors.white, fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final entry in {'All': '', 'Completed': 'completed',
                    'Pending': 'pending', 'Failed': 'failed', 'Refunded': 'refunded'}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.key),
                      selected: _status == entry.value,
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFF2A1010),
                      labelStyle: TextStyle(
                        color: _status == entry.value ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _status = entry.value),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text(e.toString(),
                style: const TextStyle(color: Colors.white54))),
            data: (data) {
              final payments = (data['payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final summary  = data['summary'] as Map<String, dynamic>? ?? {};

              return Column(children: [
                // Summary bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFF150808),
                  child: Row(children: [
                    _SummaryItem('GMV', AppFormatters.currency(
                        (summary['total_collected'] as num? ?? 0).toDouble())),
                    const SizedBox(width: 20),
                    _SummaryItem('Commission', AppFormatters.currency(
                        (summary['total_commission'] as num? ?? 0).toDouble()), Colors.green),
                    const SizedBox(width: 20),
                    _SummaryItem('Refunded', AppFormatters.currency(
                        (summary['total_refunded'] as num? ?? 0).toDouble()), AppColors.error),
                  ]),
                ),
                Expanded(
                  child: payments.isEmpty
                      ? const Center(child: Text('No payments found.',
                          style: TextStyle(color: Colors.white38)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _PaymentTile(
                            payment: payments[i],
                            onRefund: () => _refund(payments[i]['id'] as String),
                          ),
                        ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryItem(this.label, this.value, [this.color = Colors.white]);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTheme.labelSmall.copyWith(color: Colors.white38)),
      Text(value,  style: AppTheme.labelMedium.copyWith(
          color: color, fontWeight: FontWeight.w600)),
    ],
  );
}

class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onRefund;
  const _PaymentTile({required this.payment, required this.onRefund});

  static const _statusColors = {
    'completed': Colors.green,
    'pending':   Colors.amber,
    'failed':    AppColors.error,
    'refunded':  Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final status  = payment['status'] as String? ?? '';
    final color   = _statusColors[status] ?? Colors.grey;
    final amount  = (payment['amount']        as num? ?? 0).toDouble();
    final fee     = (payment['platform_fee']  as num? ?? 0).toDouble();
    final tailor  = (payment['tailor_amount'] as num? ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C0C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(payment['reference_number'] as String? ?? '',
              style: AppTheme.labelMedium.copyWith(color: Colors.white70))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: AppTheme.labelSmall.copyWith(color: color)),
          ),
          if (status == 'completed') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRefund,
              child: const Icon(Icons.undo_rounded, color: Colors.orange, size: 18),
            ),
          ],
        ]),
        const SizedBox(height: 6),
        Text('${payment['customer_name']} → ${payment['tailor_name']}',
            style: AppTheme.bodySmall.copyWith(color: Colors.white54)),
        const SizedBox(height: 6),
        Row(children: [
          Text(AppFormatters.currency(amount),
              style: AppTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Fee: ${AppFormatters.currency(fee)}',
              style: AppTheme.labelSmall.copyWith(color: Colors.green)),
          const SizedBox(width: 12),
          Text('Tailor: ${AppFormatters.currency(tailor)}',
              style: AppTheme.labelSmall.copyWith(color: Colors.white54)),
        ]),
        Text(payment['payment_method'] as String? ?? '',
            style: AppTheme.labelSmall.copyWith(color: Colors.white38)),
      ]),
    );
  }
}
