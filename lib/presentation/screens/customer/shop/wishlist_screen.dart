// lib/presentation/screens/customer/shop/wishlist_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/wishlist_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistProvider);

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
        title: Text('Wishlist',
            style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
        actions: [
          if (state.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text('Clear All',
                  style: AppTheme.labelMedium
                      .copyWith(color: AppColors.error)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.items.isEmpty
              ? _EmptyWishlist(
                  onBrowse: () => context.pop())
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(wishlistProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _WishlistCard(
                      item: state.items[i],
                      onRemove: () => _remove(context, ref, state.items[i]),
                    ),
                  ),
                ),
    );
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, WishlistItemModel item) async {
    await ref.read(wishlistProvider.notifier).toggle(item.productId);
    if (context.mounted) {
      FarhaSnackbar.info(context, '${item.productName} removed from wishlist.');
    }
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Wishlist?'),
        content: const Text(
            'All saved items will be removed from your wishlist.'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(wishlistProvider.notifier);
              final ids = ref
                  .read(wishlistProvider)
                  .items
                  .map((i) => i.productId)
                  .toList();
              for (final id in ids) {
                await notifier.toggle(id);
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ── Wishlist card ──────────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final WishlistItemModel item;
  final VoidCallback      onRemove;
  const _WishlistCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/customer/product/${item.productId}'),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Row(children: [
        // ── Thumbnail ──────────────────────────────────────
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(15)),
          child: item.productImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.productImageUrl!,
                  width: 100, height: 100,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _PlaceholderImg(),
                )
              : _PlaceholderImg(),
        ),

        // ── Info ───────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: AppTheme.titleSmall
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (item.tailorName != null) ...[
                  const SizedBox(height: 2),
                  Text(item.tailorName!,
                      style: AppTheme.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppFormatters.currency(item.price,
                          symbol: item.currency),
                      style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                    if (!item.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(100)),
                        child: Text('Unavailable',
                            style: AppTheme.labelSmall.copyWith(
                                color: AppColors.error)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Remove button ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.favorite_rounded,
                color: AppColors.error, size: 22),
            onPressed: onRemove,
            tooltip: 'Remove from wishlist',
          ),
        ),
      ]),
    ),
  );
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 100, height: 100,
    color: AppColors.surfaceContainerLow,
    child: const Center(child: Icon(Icons.image_outlined,
        color: AppColors.outline, size: 32)),
  );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyWishlist extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyWishlist({required this.onBrowse});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(
              color: AppColors.primaryFixed, shape: BoxShape.circle),
          child: const Icon(Icons.favorite_border_rounded,
              color: AppColors.primary, size: 48),
        ),
        const SizedBox(height: 20),
        Text('No saved items',
            style: AppTheme.titleMedium.copyWith(
                fontFamily: 'PlusJakartaSans')),
        const SizedBox(height: 8),
        Text(
          'Tap the heart icon on any product\nto save it here.',
          style: AppTheme.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onBrowse,
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: const Text('Browse Products'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
          ),
        ),
      ]),
    ),
  );
}
