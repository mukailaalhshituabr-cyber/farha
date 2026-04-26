// lib/presentation/screens/tailor/products/tailor_product_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/product_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/common/farha_confirm_dialog.dart';
import '../../../widgets/common/farha_snackbar.dart';
import '../../../../routes/app_router.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final tailorProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final repo = ref.watch(productRepositoryProvider);
  // Always use own=1 — server resolves the tailor UUID from the auth token and
  // bypasses is_available/is_draft filters so drafts and unavailable products
  // are visible to the tailor in their own management screen.
  final result = await repo.getProducts(own: true, limit: 100);
  return result.items;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class TailorProductManagementScreen extends ConsumerWidget {
  const TailorProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(tailorProductsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => context.go(Routes.tailorDashboard),
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => context.go(Routes.tailorDashboard),
        ),
        title: Text(l.products,
            style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppColors.primary, size: 26),
            tooltip: 'Add product',
            onPressed: () async {
              await context.push(Routes.addEditProduct);
              ref.invalidate(tailorProductsProvider);
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorBody(
          onRetry: () => ref.invalidate(tailorProductsProvider),
        ),
        data: (items) => items.isEmpty
            ? _EmptyState(
                onAdd: () async {
                  await context.push(Routes.addEditProduct);
                  ref.invalidate(tailorProductsProvider);
                },
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(tailorProductsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ProductCard(
                    product: items[i],
                    onEdit: () async {
                      await context.push(
                        Routes.addEditProduct,
                        extra: items[i],
                      );
                      ref.invalidate(tailorProductsProvider);
                    },
                    onDelete: () => _deleteProduct(context, ref, items[i]),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(Routes.addEditProduct);
          ref.invalidate(tailorProductsProvider);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    ),   // Scaffold
    );   // PopScope
  }

  Future<void> _deleteProduct(
      BuildContext context, WidgetRef ref, ProductModel product) async {
    final confirmed = await FarhaConfirmDialog.show(
      context,
      title: 'Delete Product?',
      body: '"${product.name}" will be permanently removed from your shop.',
      confirmLabel: 'Delete',
      isDangerous: true,
    );
    if (!confirmed) return;

    final repo = ref.read(productRepositoryProvider);
    final res = await repo.deleteProduct(product.id);
    if (!context.mounted) return;
    if (res.success) {
      ref.invalidate(tailorProductsProvider);
      FarhaSnackbar.success(context, 'Product deleted.');
    } else {
      FarhaSnackbar.error(context, 'Could not delete product.');
    }
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final image = product.displayImage;

    return GestureDetector(
      onTap: () => context.push('/customer/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Row(children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
            child: image != null
                ? CachedNetworkImage(
                    imageUrl: image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 90,
                        height: 90,
                        color: AppColors.surfaceContainerLow),
                    errorWidget: (_, __, ___) => _PlaceholderImage(size: 90),
                  )
                : _PlaceholderImage(size: 90),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: AppTheme.titleSmall
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(product.basePrice,
                        symbol: product.currency),
                    style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    _StatusBadge(
                      label: product.isDraft ? 'Draft' : 'Live',
                      color: product.isDraft
                          ? AppColors.onSurfaceVariant
                          : AppColors.success,
                    ),
                    if (!product.isAvailable) ...[
                      const SizedBox(width: 6),
                      _StatusBadge(
                          label: 'Unavailable', color: AppColors.warning),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.visibility_outlined,
                        size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Tap to preview',
                        style: AppTheme.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant, fontSize: 10)),
                  ]),
                ],
              ),
            ),
          ),

          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 20),
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PlaceholderImage extends StatelessWidget {
  final double size;
  const _PlaceholderImage({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        color: AppColors.surfaceContainerLow,
        child: const Center(
            child:
                Icon(Icons.image_outlined, color: AppColors.outline, size: 28)),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: AppTheme.labelSmall.copyWith(color: color, fontSize: 10)),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storefront_outlined,
              color: AppColors.outline, size: 60),
          const SizedBox(height: 16),
          Text('No Products Yet',
              style: AppTheme.titleMedium.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text('Add your first product to start selling.',
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Product'),
          ),
        ]),
      );
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.outline, size: 48),
          const SizedBox(height: 12),
          Text('Could not load products.',
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
