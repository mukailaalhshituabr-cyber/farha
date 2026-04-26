// lib/presentation/screens/customer/shop/cart_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/cart_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../../routes/app_router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.customerDashboard),
        ),
        title: Text('My Cart',
            style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text('Clear',
                  style: AppTheme.labelMedium.copyWith(color: AppColors.error)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : cart.error != null
              ? _ErrorBody(onRetry: () => ref.read(cartProvider.notifier).fetch())
              : cart.isEmpty
                  ? _EmptyCart(onShop: () => context.go(Routes.productListing))
                  : _CartBody(items: cart.items),
      bottomNavigationBar: cart.isEmpty || cart.isLoading
          ? null
          : _CheckoutBar(cart: cart),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from your cart?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(cartProvider.notifier);
              final ids = ref.read(cartProvider).items.map((i) => i.id).toList();
              for (final id in ids) {
                await notifier.removeItem(id);
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ── Cart item list ─────────────────────────────────────────────────────────────

class _CartBody extends ConsumerWidget {
  final List<CartItemModel> items;
  const _CartBody({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.read(cartProvider.notifier).fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CartItemCard(item: items[i]),
      ),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  final CartItemModel item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Container(
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
          child: item.productImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.productImageUrl!,
                  width: 100, height: 110, fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(width: 100, height: 110, color: AppColors.surfaceContainerLow),
                  errorWidget: (_, __, ___) => _PlaceholderThumb(),
                )
              : _PlaceholderThumb(),
        ),

        // Info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                if (item.shopName != null)
                  Text(item.shopName!,
                      style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                if (item.size != null)
                  Text('Size: ${item.size}',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.currency(item.subtotal, symbol: item.currency),
                  style: AppTheme.titleSmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                // Quantity controls
                Row(children: [
                  _QtyButton(
                    icon: Icons.remove_rounded,
                    onPressed: () => notifier.updateQuantity(item.id, item.quantity - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('${item.quantity}',
                        style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  _QtyButton(
                    icon: Icons.add_rounded,
                    onPressed: () => notifier.updateQuantity(item.id, item.quantity + 1),
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Remove button
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 20),
          tooltip: 'Remove',
          onPressed: () => notifier.removeItem(item.id),
        ),
        const SizedBox(width: 4),
      ]),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Icon(icon, size: 16, color: AppColors.onBackground),
    ),
  );
}

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 100, height: 110, color: AppColors.surfaceContainerLow,
    child: const Center(child: Icon(Icons.image_outlined, color: AppColors.outline, size: 32)),
  );
}

// ── Checkout bar ───────────────────────────────────────────────────────────────

class _CheckoutBar extends ConsumerWidget {
  final CartState cart;
  const _CheckoutBar({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${cart.count} item${cart.count == 1 ? '' : 's'}',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
            Text(
              AppFormatters.currency(cart.total, symbol: cart.items.first.currency),
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push(Routes.payment, extra: cart.items),
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: Text('Proceed to Checkout  →',
                style: AppTheme.labelLarge),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shopping_bag_outlined, color: AppColors.outline, size: 72),
      const SizedBox(height: 16),
      Text('Your cart is empty',
          style: AppTheme.titleMedium.copyWith(color: AppColors.onSurface)),
      const SizedBox(height: 6),
      Text('Add products to start shopping.',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: onShop,
        icon: const Icon(Icons.storefront_outlined, size: 18),
        label: const Text('Browse Products'),
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
      const Icon(Icons.wifi_off_rounded, color: AppColors.outline, size: 48),
      const SizedBox(height: 12),
      Text('Could not load cart.',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 16),
      FilledButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}
