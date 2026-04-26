// lib/presentation/screens/customer/shop/search_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/product_provider.dart';
// ── Provider ───────────────────────────────────────────────────────────────────

final _searchResultsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, q) async {
  if (q.trim().length < 2) return [];
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.getProducts(search: q.trim(), limit: 30);
  return result.items;
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  String _query = '';

  static const _suggestions = [
    'Boubou', 'Kaftan', 'Agbada', 'Robe', 'Costume', 'Wedding', 'Children',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) => setState(() => _query = q);

  @override
  Widget build(BuildContext context) {
    final query   = _query;
    final results = ref.watch(_searchResultsProvider(query));

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
        title: TextField(
          controller: _ctrl,
          focusNode:  _focus,
          onChanged:  _search,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Search products, tailors…',
            hintStyle: AppTheme.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant),
            border: InputBorder.none,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: AppColors.onSurfaceVariant, size: 20),
                    onPressed: () {
                      _ctrl.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          style: AppTheme.bodyLarge,
        ),
      ),
      body: query.trim().length < 2
          ? _SuggestionsBody(
              suggestions: _suggestions,
              onTap: (s) {
                _ctrl.text = s;
                _search(s);
              },
            )
          : results.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => _EmptyResults(query: query),
              data: (items) => items.isEmpty
                  ? _EmptyResults(query: query)
                  : _ResultsGrid(items: items),
            ),
    );
  }
}

// ── Suggestions ────────────────────────────────────────────────────────────────

class _SuggestionsBody extends StatelessWidget {
  final List<String>  suggestions;
  final void Function(String) onTap;
  const _SuggestionsBody({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Popular searches',
          style: AppTheme.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant, letterSpacing: 0.8)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: suggestions.map((s) => GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_rounded,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(s, style: AppTheme.bodyMedium),
            ]),
          ),
        )).toList(),
      ),
    ]),
  );
}

// ── Results grid ───────────────────────────────────────────────────────────────

class _ResultsGrid extends StatelessWidget {
  final List<ProductModel> items;
  const _ResultsGrid({required this.items});

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.72,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: items.length,
    itemBuilder: (_, i) => _ProductCard(product: items[i]),
  );
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/customer/product/${product.id}'),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: product.displayImage != null
                ? CachedNetworkImage(
                    imageUrl: product.displayImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorWidget: (_, __, ___) => _PlaceholderImg(),
                  )
                : _PlaceholderImg(),
          ),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name,
                style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(AppFormatters.currency(product.basePrice, symbol: product.currency),
                style: AppTheme.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    ),
  );
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceContainerLow,
    child: const Center(child: Icon(Icons.image_outlined,
        color: AppColors.outline, size: 36)),
  );
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.search_off_rounded,
          color: AppColors.outline, size: 56),
      const SizedBox(height: 12),
      Text('No results for "$query"',
          style: AppTheme.titleSmall.copyWith(color: AppColors.onSurface)),
      const SizedBox(height: 6),
      Text('Try a different keyword.',
          style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
    ]),
  );
}
