// lib/data/repositories/product_repository.dart
import '../models/product_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class ProductRepository {
  final ApiClient _api;
  const ProductRepository(this._api);

  Future<ListResult<ProductModel>> getProducts({
    String? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? tailorId,
    bool    own  = false,  // tailor fetches their own products without knowing their UUID
    String? sort,          // 'rating' | 'price_asc' | 'price_desc' | 'newest'
    int     page = 1,
    int     limit = 20,
  }) async {
    final res = await _api.get(ApiConstants.productList, params: {
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (tailorId != null) 'tailor_id': tailorId,
      if (own)              'own':       '1',
      if (sort != null)     'sort':      sort,
      'page':  page,
      'limit': limit,
    });
    if (!res.success) return ListResult.error(res.message);
    final data = res.data as Map<String, dynamic>;
    return ListResult.success(
      items: (data['items'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
      total:    data['total'] as int? ?? 0,
      hasMore:  data['has_more'] as bool? ?? false,
    );
  }

  Future<ProductResult> getProduct(String id) async {
    final res = await _api.get(ApiConstants.productDetail, params: {'product_id': id});
    if (!res.success) return ProductResult.error(res.message);
    return ProductResult.success(
        ProductModel.fromJson(res.data as Map<String, dynamic>));
  }

  Future<ListResult<ProductModel>> search(String query) async {
    final res = await _api.get(ApiConstants.productSearch, params: {'q': query});
    if (!res.success) return ListResult.error(res.message);
    final items = (res.data as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    return ListResult.success(items: items, total: items.length);
  }

  // Tailor-only
  Future<ApiResponse> createProduct(Map<String, dynamic> data) =>
      _api.post(ApiConstants.productCreate, data: data);

  Future<ApiResponse> updateProduct(String id, Map<String, dynamic> data) =>
      _api.post('${ApiConstants.productUpdate}?id=$id', data: data);

  Future<ApiResponse> deleteProduct(String id) =>
      _api.post('${ApiConstants.productDelete}?id=$id', data: {'id': id});
}

class ListResult<T> {
  final bool     success;
  final List<T>  items;
  final int      total;
  final bool     hasMore;
  final String   error;

  const ListResult._({
    required this.success,
    this.items   = const [],
    this.total   = 0,
    this.hasMore = false,
    this.error   = '',
  });

  factory ListResult.success({required List<T> items, required int total, bool hasMore = false}) =>
      ListResult._(success: true, items: items, total: total, hasMore: hasMore);

  factory ListResult.error(String msg) =>
      ListResult._(success: false, error: msg);
}

class ProductResult {
  final bool         success;
  final ProductModel? product;
  final String        error;

  const ProductResult._({required this.success, this.product, this.error = ''});

  factory ProductResult.success(ProductModel p) =>
      ProductResult._(success: true, product: p);
  factory ProductResult.error(String msg) =>
      ProductResult._(success: false, error: msg);
}
