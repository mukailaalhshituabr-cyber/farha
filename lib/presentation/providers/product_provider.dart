// lib/presentation/providers/product_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/tailor_repository.dart';
import 'auth_provider.dart';

// ── Repository providers ──────────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) =>
    ProductRepository(ref.watch(apiClientProvider)));

final tailorRepositoryProvider = Provider<TailorRepository>((ref) =>
    TailorRepository(ref.watch(apiClientProvider)));

// ── Product list state ────────────────────────────────────────────────────
class ProductListState {
  final List<ProductModel> items;
  final bool     isLoading;
  final bool     isLoadingMore;
  final bool     hasMore;
  final String?  error;
  final String?  selectedCategory;
  final String?  searchQuery;
  final String   sort;
  final int      page;

  const ProductListState({
    this.items           = const [],
    this.isLoading       = false,
    this.isLoadingMore   = false,
    this.hasMore         = true,
    this.error,
    this.selectedCategory,
    this.searchQuery,
    this.sort            = 'newest',
    this.page            = 1,
  });

  // Use clearCategory / clearSearch sentinels to explicitly null out optional fields.
  static const _clear = Object();

  ProductListState copyWith({
    List<ProductModel>? items, bool? isLoading,
    bool? isLoadingMore, bool? hasMore, String? error,
    Object? selectedCategory = _clear,
    Object? searchQuery      = _clear,
    String? sort, int? page,
  }) => ProductListState(
    items:             items             ?? this.items,
    isLoading:         isLoading         ?? this.isLoading,
    isLoadingMore:     isLoadingMore     ?? this.isLoadingMore,
    hasMore:           hasMore           ?? this.hasMore,
    error:             error,
    selectedCategory:  identical(selectedCategory, _clear)
                           ? this.selectedCategory
                           : selectedCategory as String?,
    searchQuery:       identical(searchQuery, _clear)
                           ? this.searchQuery
                           : searchQuery as String?,
    sort:              sort              ?? this.sort,
    page:              page              ?? this.page,
  );
}

class ProductNotifier extends StateNotifier<ProductListState> {
  final ProductRepository _repo;
  ProductNotifier(this._repo) : super(const ProductListState()) {
    load();
  }

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: refresh || page == 1, page: page);

    final result = await _repo.getProducts(
      categoryId: state.selectedCategory,
      search:     state.searchQuery,
      sort:       state.sort,
      page:       page,
    );

    if (!result.success) {
      state = state.copyWith(isLoading: false, error: result.error);
      return;
    }

    state = state.copyWith(
      items:     refresh ? result.items : [...state.items, ...result.items],
      hasMore:   result.hasMore,
      isLoading: false,
      page:      page + 1,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    await load();
    state = state.copyWith(isLoadingMore: false);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(selectedCategory: categoryId, page: 1);
    load(refresh: true);
  }

  void setSort(String sort) {
    state = state.copyWith(sort: sort, page: 1);
    load(refresh: true);
  }

  void search(String query) {
    state = state.copyWith(
      searchQuery: query.isEmpty ? null : query,
      page: 1,
    );
    load(refresh: true);
  }

  void refresh() => load(refresh: true);
}

final productProvider =
    StateNotifierProvider<ProductNotifier, ProductListState>((ref) =>
        ProductNotifier(ref.watch(productRepositoryProvider)));

// ── Single product ────────────────────────────────────────────────────────
final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) async {
  final result = await ref.watch(productRepositoryProvider).getProduct(id);
  return result.product;
});
