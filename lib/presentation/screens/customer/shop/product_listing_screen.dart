// lib/presentation/screens/customer/shop/product_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';
import '../../../widgets/common/loading_overlay.dart';

class ProductListingScreen extends ConsumerStatefulWidget {
  const ProductListingScreen({super.key});

  @override
  ConsumerState<ProductListingScreen> createState() => _State();
}

class _State extends ConsumerState<ProductListingScreen> {
  final _searchCtrl  = TextEditingController();
  final _debouncer   = Debouncer();
  final _scrollCtrl  = ScrollController();
  String? _selectedCategoryId;

  static const _categories = [
    {'id': null,                                        'label': 'All'},
    {'id': 'cat00000-0000-0000-0000-000000000001',      'label': 'Boubou'},
    {'id': 'cat00000-0000-0000-0000-000000000002',      'label': 'Kaftan'},
    {'id': 'cat00000-0000-0000-0000-000000000003',      'label': 'Agbada'},
    {'id': 'cat00000-0000-0000-0000-000000000004',      'label': 'Dress'},
    {'id': 'cat00000-0000-0000-0000-000000000005',      'label': 'Suit'},
    {'id': 'cat00000-0000-0000-0000-000000000006',      'label': "Children's"},
    {'id': 'cat00000-0000-0000-0000-000000000007',      'label': 'Wedding'},
    {'id': 'cat00000-0000-0000-0000-000000000008',      'label': 'Accessories'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Refresh products each time this screen is opened so new items are visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).refresh();
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final s = ref.read(productProvider);
      if (s.hasMore && !s.isLoading) {
        ref.read(productProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onBackground),
          onPressed: () => context.canPop() ? context.pop() : context.go('/customer/home'),
        ),
        title: Text('Our Collection',
          style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.onBackground),
            onPressed: () => _showSortSheet(context),
          ),
        ],
      ),
      body: Column(children: [
        // ── Search bar ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search garments, tailors...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.onSurfaceVariant, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(productProvider.notifier).search('');
                      })
                  : null,
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onChanged: (q) {
              setState(() {});
              _debouncer.run(() =>
                  ref.read(productProvider.notifier).search(q));
            },
          ),
        ),

        // ── Category chips ────────────────────────────────────────
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: _categories.map((cat) {
              final id       = cat['id'];
              final selected = _selectedCategoryId == id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat['label'] as String),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedCategoryId = id);
                    ref.read(productProvider.notifier).setCategory(id);
                  },
                  backgroundColor:      AppColors.surfaceContainerLow,
                  selectedColor:        AppColors.primaryFixed,
                  checkmarkColor:       AppColors.primary,
                  labelStyle: AppTheme.labelMedium.copyWith(
                    color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // ── Products grid ─────────────────────────────────────────
        Expanded(
          child: productState.isLoading && productState.items.isEmpty
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : productState.items.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            color: AppColors.outline, size: 48),
                        const SizedBox(height: 12),
                        Text('No products found',
                          style: AppTheme.titleSmall.copyWith(
                              color: AppColors.onSurfaceVariant)),
                      ]))
                  : GridView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: productState.items.length +
                          (productState.isLoading && productState.items.isNotEmpty ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= productState.items.length) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2)));
                        }
                        return _ProductCard(
                          product: productState.items[i],
                          onTap: () => context.push(
                              '/customer/product/${productState.items[i].id}'),
                        );
                      },
                    ),
        ),
      ]),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2))),
          Text('Sort by', style: AppTheme.titleLarge),
          const SizedBox(height: 16),
          ...['newest', 'rating', 'price_asc', 'price_desc'].map((sort) {
            final labels = {
              'newest': 'Newest first',
              'rating': 'Top rated',
              'price_asc': 'Price: Low to High',
              'price_desc': 'Price: High to Low',
            };
            return ListTile(
              title: Text(labels[sort]!, style: AppTheme.bodyMedium),
              onTap: () {
                ref.read(productProvider.notifier).setSort(sort);
                Navigator.pop(context);
              },
            );
          }),
        ]),
      ),
    );
  }
}

// ── Product card ───────────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(wishlistProvider).isFavorite(product.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.displayImage != null
                  ? CachedNetworkImage(
                      imageUrl: product.displayImage!,
                      height: 160, width: double.infinity, fit: BoxFit.cover,
                      placeholder: (_, __) => const FarhaShimmer(height: 160, radius: 0),
                      errorWidget: (_, __, ___) => _ImagePlaceholder())
                  : _ImagePlaceholder(),
            ),
            // Favorite
            Positioned(top: 8, right: 8,
              child: GestureDetector(
                onTap: () => ref.read(wishlistProvider.notifier)
                    .toggle(product.id),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 16,
                    color: isFav ? AppColors.error : AppColors.onSurfaceVariant,
                  ),
                ),
              )),
          ]),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: AppTheme.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(product.tailorName,
                style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star_rounded, size: 12, color: AppColors.secondary),
                const SizedBox(width: 2),
                Text(AppFormatters.rating(product.rating),
                  style: AppTheme.labelSmall.copyWith(color: AppColors.secondary)),
                const Spacer(),
                Flexible(child: Text(
                  AppFormatters.currency(product.basePrice, symbol: product.currency),
                  style: AppTheme.labelMedium.copyWith(color: AppColors.primary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 160, color: AppColors.surfaceContainerLow,
    child: const Center(child: Icon(Icons.image_outlined,
        color: AppColors.outline, size: 36)));
}
