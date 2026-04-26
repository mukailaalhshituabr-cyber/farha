// lib/presentation/screens/admin/admin_products_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';
import 'admin_shell.dart';

final _adminProductsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiConstants.adminProducts, params: {'limit': 50});
  if (!res.success) throw Exception(res.message);
  return res.data as Map<String, dynamic>;
});

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {

  Future<void> _removeProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A1010),
        title: const Text('Remove Product', style: TextStyle(color: Colors.white)),
        content: const Text('This product will be permanently deleted.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await ref.read(apiClientProvider)
        .delete(ApiConstants.adminProducts, params: {'product_id': productId});
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context, 'Product removed.');
      ref.invalidate(_adminProductsProvider);
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  Future<void> _toggleAvailability(String productId, bool currentlyAvailable) async {
    final action = currentlyAvailable ? 'disable' : 'enable';
    final res = await ref.read(apiClientProvider).post(
        ApiConstants.adminProducts, data: {'product_id': productId, 'action': action});
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context, res.message);
      ref.invalidate(_adminProductsProvider);
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(_adminProductsProvider);

    return AdminShell(
      child: Column(children: [
        Container(
          color: const Color(0xFF1A0A0A),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Text('Product Moderation', style: AppTheme.headlineMedium.copyWith(
              color: Colors.white, fontFamily: 'PlusJakartaSans')),
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text(e.toString(),
                style: const TextStyle(color: Colors.white54))),
            data: (data) {
              final products = (data['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              if (products.isEmpty) {
                return const Center(child: Text('No products.',
                    style: TextStyle(color: Colors.white38)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = products[i];
                  final isAvailable = p['is_available'] as bool? ?? true;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E0C0C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Row(children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (p['main_image'] as String?)?.isNotEmpty == true
                            ? Image.network(p['main_image'] as String,
                                width: 52, height: 52, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _ImgPlaceholder())
                            : const _ImgPlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] as String? ?? '',
                            style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${p['shop_name']} · ${p['tailor_name']}',
                            style: AppTheme.bodySmall.copyWith(color: Colors.white54),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${AppFormatters.currency((p['base_price'] as num? ?? 0).toDouble())}  ·  ⭐ ${p['rating']}  ·  ${p['total_sales']} sold',
                            style: AppTheme.labelSmall.copyWith(color: Colors.white38)),
                      ])),
                      Column(children: [
                        IconButton(
                          icon: Icon(
                            isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white38, size: 20,
                          ),
                          tooltip: isAvailable ? 'Disable' : 'Enable',
                          onPressed: () => _toggleAvailability(p['id'] as String, isAvailable),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error, size: 20),
                          tooltip: 'Remove',
                          onPressed: () => _removeProduct(p['id'] as String),
                        ),
                      ]),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    width: 52, height: 52,
    color: const Color(0xFF2A1010),
    child: const Icon(Icons.image_outlined, color: Colors.white24, size: 24),
  );
}
