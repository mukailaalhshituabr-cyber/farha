// lib/presentation/widgets/customer/product_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../common/loading_overlay.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final bool         showFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(wishlistProvider).isFavorite(product.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Image ──────────────────────────────────────────────────
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.displayImage != null
                  ? CachedNetworkImage(
                      imageUrl:   product.displayImage!,
                      height:     160,
                      width:      double.infinity,
                      fit:        BoxFit.cover,
                      placeholder: (_, __) => const FarhaShimmer(height: 160, radius: 0),
                      errorWidget:  (_, __, ___) => _PlaceholderImage(),
                    )
                  : _PlaceholderImage(),
            ),
            // Favorite button
            if (showFavorite)
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => ref.read(wishlistProvider.notifier).toggle(product.id),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color:        AppColors.surfaceContainerLowest.withValues(alpha:0.9),
                      shape:        BoxShape.circle,
                      border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                    ),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size:  18,
                      color: isFav ? AppColors.error : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ]),

          // ── Info ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name,
                style:    AppTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(product.tailorName,
                style:    AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
                const SizedBox(width: 2),
                Text(AppFormatters.rating(product.rating),
                    style: AppTheme.labelSmall.copyWith(color: AppColors.secondary)),
                const Spacer(),
                Text(AppFormatters.currency(product.basePrice, symbol: product.currency),
                  style: AppTheme.titleSmall.copyWith(color: AppColors.primary),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 160, color: AppColors.surfaceContainerLow,
    child: const Center(child: Icon(Icons.image_outlined,
        color: AppColors.outline, size: 40)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/presentation/widgets/customer/tailor_card.dart

class TailorCard extends StatelessWidget {
  final dynamic  tailor;   // TailorModel
  final VoidCallback onTap;
  final VoidCallback? onSelect;
  final bool showSelectButton;

  const TailorCard({
    super.key,
    required this.tailor,
    required this.onTap,
    this.onSelect,
    this.showSelectButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Avatar
            CircleAvatar(
              radius:   28,
              backgroundColor: AppColors.primaryFixed,
              backgroundImage: tailor.profilePhoto != null
                  ? CachedNetworkImageProvider(tailor.profilePhoto!) : null,
              child: tailor.profilePhoto == null
                  ? Text(AppFormatters.initials(tailor.fullName),
                      style: AppTheme.titleMedium.copyWith(color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(tailor.shopName,
                  style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (tailor.isVerified)
                  const Icon(Icons.verified_rounded, size: 16, color: AppColors.info),
              ]),
              Text(tailor.fullName,
                style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(AppFormatters.rating(tailor.rating.toDouble()),
                style: AppTheme.labelSmall.copyWith(color: AppColors.secondary)),
            const SizedBox(width: 4),
            Text('(${tailor.totalReviews} reviews)',
                style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            if (tailor.distanceKm != null) ...[
              const Spacer(),
              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.onSurfaceVariant),
              Text('${tailor.distanceKm!.toStringAsFixed(1)} km',
                  style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ]),
          if (tailor.shopLocation != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.storefront_outlined, size: 12, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(child: Text(tailor.shopLocation!,
                style:    AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          if (showSelectButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text('Select Tailor'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
