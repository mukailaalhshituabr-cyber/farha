// lib/presentation/screens/customer/shop/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';
import '../../../widgets/common/loading_overlay.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _State();
}

class _State extends ConsumerState<ProductDetailScreen> {
  String? _selectedSize;
  int     _quantity      = 1;
  bool    _isAddingCart  = false;
  bool    _openingChat   = false;
  bool    _descExpanded  = true;

  static const _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

  Future<void> _openChat(String tailorId) async {
    setState(() => _openingChat = true);
    final api = ref.read(apiClientProvider);
    final res = await api.post(
      ApiConstants.conversations,
      data: {'tailor_id': tailorId},
    );
    if (!mounted) return;
    setState(() => _openingChat = false);

    if (res.success) {
      final convId =
          (res.data as Map<String, dynamic>?)?['conversation_id'] as String? ?? '';
      if (convId.isNotEmpty) {
        context.push('/customer/chat/$convId');
        return;
      }
    }
    FarhaSnackbar.error(context, 'Could not open chat. Please try again.');
  }

  Future<void> _addToCart(ProductModel product) async {
    if (_selectedSize == null) {
      FarhaSnackbar.error(context, 'Please select a size first.');
      return;
    }
    setState(() => _isAddingCart = true);

    final ok = await ref.read(cartProvider.notifier)
        .addItem(product.id, _quantity, _selectedSize);

    if (!mounted) return;
    setState(() => _isAddingCart = false);

    if (ok) {
      FarhaSnackbar.success(context, '${product.name} added to cart!');
    } else {
      FarhaSnackbar.error(context, 'Could not add to cart. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final isFav = ref.watch(wishlistProvider)
        .isFavorite(widget.productId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(
              color: AppColors.primary))),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Could not load product.',
            style: AppTheme.bodyMedium))),
        data: (product) {
          if (product == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('Product not found.',
                  style: AppTheme.bodyMedium)));
          }
          return LoadingOverlay(
            isLoading: _isAddingCart,
            child: CustomScrollView(slivers: [
              // ── Image + back/fav ─────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha:0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.onBackground, size: 20),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(Routes.productListing);
                        }
                      },
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha:0.9),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.error : AppColors.onBackground,
                          size: 20,
                        ),
                        onPressed: () => ref.read(wishlistProvider.notifier)
                            .toggle(product.id),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: product.displayImage != null
                      ? CachedNetworkImage(
                          imageUrl: product.displayImage!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AppColors.surfaceContainerLow),
                          errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceContainerLow,
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.outline, size: 48)))
                      : Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.outline, size: 48)),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag
                      Text(product.categoryName.toUpperCase(),
                        style: AppTheme.labelSmall.copyWith(
                            color: AppColors.primary, letterSpacing: 1.5)),
                      const SizedBox(height: 6),

                      // Name
                      Text(product.name,
                        style: AppTheme.headlineMedium.copyWith(
                            fontFamily: 'PlusJakartaSans')),
                      const SizedBox(height: 8),

                      // Rating + tailor
                      Row(children: [
                        const Icon(Icons.star_rounded, size: 16,
                            color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(AppFormatters.rating(product.rating),
                          style: AppTheme.labelMedium.copyWith(
                              color: AppColors.secondary)),
                        Text(' (${product.totalReviews} Reviews)',
                          style: AppTheme.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant)),
                        const Spacer(),
                        Text(AppFormatters.currency(
                            product.basePrice, symbol: product.currency),
                          style: AppTheme.headlineSmall.copyWith(
                              color: AppColors.primary)),
                      ]),
                      const SizedBox(height: 4),

                      Row(children: [
                        const Icon(Icons.store_outlined, size: 14,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Master Tailor: ${product.tailorName}',
                          style: AppTheme.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant)),
                        if (true) // verified
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded, size: 14,
                                color: AppColors.primary)),
                      ]),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ── Size selection ─────────────────────────
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Size',
                            style: AppTheme.titleMedium),
                          TextButton(
                            onPressed: () {},
                            child: Text('Size Guide',
                              style: AppTheme.labelSmall.copyWith(
                                  color: AppColors.primary))),
                        ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, children: _sizes.map((size) {
                        final available = product.availableSizes.isEmpty ||
                            product.availableSizes.contains(size);
                        final selected  = _selectedSize == size;
                        return GestureDetector(
                          onTap: available
                              ? () => setState(() => _selectedSize = size)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 52, height: 48,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : available
                                      ? AppColors.surfaceContainerLow
                                      : AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.outlineVariant,
                                width: selected ? 2 : 0.5,
                              ),
                            ),
                            child: Center(child: Text(size,
                              style: AppTheme.labelMedium.copyWith(
                                color: selected
                                    ? AppColors.onPrimary
                                    : available
                                        ? AppColors.onBackground
                                        : AppColors.outline,
                              ))),
                          ),
                        );
                      }).toList()),

                      const SizedBox(height: 20),

                      // ── Quantity ───────────────────────────────
                      Row(children: [
                        Text('Quantity', style: AppTheme.titleMedium),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              constraints: const BoxConstraints(
                                  minWidth: 40, minHeight: 40),
                            ),
                            Text('$_quantity',
                              style: AppTheme.titleMedium),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () => setState(() => _quantity++),
                              constraints: const BoxConstraints(
                                  minWidth: 40, minHeight: 40),
                            ),
                          ]),
                        ),
                      ]),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ── Description ────────────────────────────
                      GestureDetector(
                        onTap: () => setState(
                            () => _descExpanded = !_descExpanded),
                        child: Row(children: [
                          Text('Description', style: AppTheme.titleMedium),
                          const Spacer(),
                          Icon(_descExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                              color: AppColors.onSurfaceVariant),
                        ]),
                      ),
                      if (_descExpanded && product.description != null) ...[
                        const SizedBox(height: 10),
                        Text(product.description!,
                          style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant, height: 1.7)),
                      ],

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ── Crafted by ─────────────────────────────
                      Text('Crafted By', style: AppTheme.titleMedium),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.outlineVariant, width: 0.5),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryFixed,
                            child: Text(
                              AppFormatters.initials(product.tailorName),
                              style: AppTheme.titleSmall.copyWith(
                                  color: AppColors.primary)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.tailorName,
                                style: AppTheme.titleSmall),
                              Text(product.categoryName,
                                style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant)),
                            ],
                          )),
                          TextButton(
                            onPressed: () => context.push(
                                '/customer/tailor/${product.tailorId}'),
                            child: Text('View Profile',
                              style: AppTheme.labelSmall.copyWith(
                                  color: AppColors.primary))),
                        ]),
                      ),

                      const SizedBox(height: 20),

                      // ── Reviews preview ────────────────────────
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Customer Reviews', style: AppTheme.titleMedium),
                          TextButton(
                            onPressed: () => context.push(
                                '/customer/reviews/${product.id}'),
                            child: Text('View all',
                              style: AppTheme.labelSmall.copyWith(
                                  color: AppColors.primary))),
                        ]),
                    ],
                  ),
                ),
              ),
            ]),
          );
        },
      ),

      // ── Bottom bar: Message + Add to Cart ────────────────────────
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => product == null ? null : Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(top: BorderSide(
                color: AppColors.outlineVariant, width: 0.5)),
          ),
          child: Row(children: [
            OutlinedButton.icon(
              onPressed: _openingChat ? null : () => _openChat(product.tailorId),
              icon: _openingChat
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: _isAddingCart ? null : () => _addToCart(product),
              icon: _isAddingCart
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: const Text('Add to Cart'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
            )),
          ]),
        ),
        orElse: () => null,
      ),
    );
  }
}
