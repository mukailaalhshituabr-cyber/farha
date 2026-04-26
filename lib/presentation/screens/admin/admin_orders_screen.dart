// lib/presentation/screens/admin/admin_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';
import 'admin_shell.dart';

final _adminOrdersProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, status) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiConstants.adminOrders,
      params: {'status': status, 'limit': 50});
  if (!res.success) throw Exception(res.message);
  return res.data as Map<String, dynamic>;
});

const _statuses = ['', 'pending', 'confirmed', 'cutting', 'sewing', 'ready', 'delivered', 'cancelled'];
const _labels   = ['All', 'Pending', 'Confirmed', 'Cutting', 'Sewing', 'Ready', 'Delivered', 'Cancelled'];

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _status = '';

  Future<void> _overrideStatus(String orderId, String newStatus) async {
    final res = await ref.read(apiClientProvider).post(
        ApiConstants.adminOrders, data: {'order_id': orderId, 'status': newStatus});
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context, 'Order status updated.');
      ref.invalidate(_adminOrdersProvider(_status));
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_adminOrdersProvider(_status));

    return AdminShell(
      child: Column(children: [
        Container(
          color: const Color(0xFF1A0A0A),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('All Orders', style: AppTheme.headlineMedium.copyWith(
                color: Colors.white, fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_statuses.length, (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_labels[i]),
                    selected: _status == _statuses[i],
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFF2A1010),
                    labelStyle: TextStyle(
                      color: _status == _statuses[i] ? Colors.white : Colors.white54,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _status = _statuses[i]),
                  ),
                )),
              ),
            ),
          ]),
        ),
        Expanded(
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text(e.toString(),
                style: const TextStyle(color: Colors.white54))),
            data: (data) {
              final orders = (data['orders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              if (orders.isEmpty) {
                return const Center(child: Text('No orders found.',
                    style: TextStyle(color: Colors.white38)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _OrderTile(
                  order: orders[i],
                  onOverride: (s) => _overrideStatus(orders[i]['id'] as String, s),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final void Function(String) onOverride;
  const _OrderTile({required this.order, required this.onOverride});

  static const _statusColors = {
    'pending':   Colors.amber,
    'confirmed': Colors.blue,
    'cutting':   Colors.orange,
    'sewing':    Colors.purple,
    'ready':     Colors.teal,
    'delivered': Colors.green,
    'cancelled': AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final status   = order['status'] as String? ?? '';
    final color    = _statusColors[status] ?? Colors.grey;
    final total    = (order['total_amount'] as num? ?? 0).toDouble();
    final fee      = (order['platform_fee_collected'] as num? ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C0C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(order['reference_number'] as String? ?? '',
              style: AppTheme.labelMedium.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: AppTheme.labelSmall.copyWith(color: color)),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: const Color(0xFF2A1010),
            icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 18),
            onSelected: onOverride,
            itemBuilder: (_) => _statuses.skip(1).map((s) =>
              PopupMenuItem(value: s,
                  child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
          ),
        ]),
        const SizedBox(height: 6),
        Text('${order['customer_name']} → ${order['tailor_name']} (${order['shop_name']})',
            style: AppTheme.bodySmall.copyWith(color: Colors.white54)),
        const SizedBox(height: 6),
        Row(children: [
          Text(AppFormatters.currency(total), style: AppTheme.labelMedium.copyWith(color: Colors.white)),
          const Spacer(),
          Text('Fee: ${AppFormatters.currency(fee)}',
              style: AppTheme.labelSmall.copyWith(color: Colors.green)),
        ]),
      ]),
    );
  }
}
