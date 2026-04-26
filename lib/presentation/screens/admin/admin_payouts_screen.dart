// lib/presentation/screens/admin/admin_payouts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';
import 'admin_shell.dart';

final _adminPayoutsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, status) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiConstants.adminPayouts,
      params: {'status': status, 'limit': 50});
  if (!res.success) throw Exception(res.message);
  return res.data as Map<String, dynamic>;
});

class AdminPayoutsScreen extends ConsumerStatefulWidget {
  const AdminPayoutsScreen({super.key});
  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  String _status = 'pending';

  Future<void> _review(String payoutId, String action) async {
    String? notes;

    if (action == 'reject') {
      final ctrl = TextEditingController();
      notes = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF2A1010),
          title: const Text('Rejection Reason', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Optional reason…',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (notes == null) return;
    }

    final res = await ref.read(apiClientProvider).post(ApiConstants.adminPayouts,
        data: {'payout_id': payoutId, 'action': action, if (notes != null) 'notes': notes});
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context, action == 'approve' ? 'Payout approved.' : 'Payout rejected.');
      ref.invalidate(_adminPayoutsProvider(_status));
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payoutsAsync = ref.watch(_adminPayoutsProvider(_status));

    return AdminShell(
      child: Column(children: [
        Container(
          color: const Color(0xFF1A0A0A),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Payout Requests', style: AppTheme.headlineMedium.copyWith(
                color: Colors.white, fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final entry in {'Pending': 'pending', 'Approved': 'approved',
                    'Completed': 'completed', 'Rejected': 'rejected', 'All': 'all'}.entries)
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
          child: payoutsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text(e.toString(),
                style: const TextStyle(color: Colors.white54))),
            data: (data) {
              final payouts = (data['payouts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              if (payouts.isEmpty) {
                return const Center(child: Text('No payout requests.',
                    style: TextStyle(color: Colors.white38)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: payouts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PayoutCard(
                  payout: payouts[i],
                  onReview: (action) => _review(payouts[i]['id'] as String, action),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final Map<String, dynamic>  payout;
  final void Function(String) onReview;
  const _PayoutCard({required this.payout, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final status    = payout['status'] as String? ?? 'pending';
    final amount    = (payout['amount']       as num? ?? 0).toDouble();
    final earned    = (payout['total_earned'] as num? ?? 0).toDouble();
    final paidOut   = (payout['total_paid_out'] as num? ?? 0).toDouble();
    final available = earned - paidOut;
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C0C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.07),
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(payout['tailor_name'] as String? ?? '',
                style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            Text(payout['shop_name'] as String? ?? '',
                style: AppTheme.bodySmall.copyWith(color: Colors.white54)),
          ])),
          _StatusBadge(status),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _InfoBox('Request', AppFormatters.currency(amount), Colors.white),
          const SizedBox(width: 10),
          _InfoBox('Total Earned', AppFormatters.currency(earned), Colors.teal),
          const SizedBox(width: 10),
          _InfoBox('Available', AppFormatters.currency(available), Colors.green),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.phone_android_rounded, size: 14, color: Colors.white38),
          const SizedBox(width: 4),
          Text('${payout['payout_method']} · ${payout['account'] ?? '—'}',
              style: AppTheme.labelSmall.copyWith(color: Colors.white54)),
          const Spacer(),
          Text(payout['tailor_phone'] as String? ?? '',
              style: AppTheme.labelSmall.copyWith(color: Colors.white38)),
        ]),
        if (isPending) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onReview('reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => onReview('approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Approve'),
              ),
            ),
          ]),
        ],
        if (payout['notes'] != null) ...[
          const SizedBox(height: 8),
          Text('Note: ${payout['notes']}',
              style: AppTheme.labelSmall.copyWith(color: Colors.white38)),
        ],
      ]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _InfoBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.labelSmall.copyWith(
            color: Colors.white38, fontSize: 10)),
        Text(value, style: AppTheme.labelMedium.copyWith(
            color: color, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  static const _colors = {
    'pending':    Colors.orange,
    'approved':   Colors.blue,
    'processing': Colors.purple,
    'completed':  Colors.green,
    'rejected':   AppColors.error,
  };
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: AppTheme.labelSmall.copyWith(color: color)),
    );
  }
}
