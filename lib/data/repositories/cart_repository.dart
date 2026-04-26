// lib/data/repositories/cart_repository.dart
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/cart_model.dart';

class CartRepository {
  final ApiClient _api;
  const CartRepository(this._api);

  Future<CartListResult> getCart() async {
    final res = await _api.get(ApiConstants.cartGet);
    if (!res.success) return CartListResult.error(res.message);
    final data  = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CartListResult.success(items);
  }

  Future<ApiResponse> addItem({
    required String productId,
    required int quantity,
    String? size,
  }) =>
      _api.post(ApiConstants.cartAdd, data: {
        'product_id': productId,
        'quantity':   quantity,
        if (size != null) 'size': size,
      });

  Future<ApiResponse> updateItem(String cartItemId, int quantity) =>
      _api.put(
          '${ApiConstants.cartUpdate}?id=${Uri.encodeComponent(cartItemId)}',
          data: {'quantity': quantity});

  Future<ApiResponse> removeItem(String cartItemId) =>
      _api.delete(ApiConstants.cartRemove,
          params: {'id': cartItemId});
}

class CartListResult {
  final bool              success;
  final List<CartItemModel> items;
  final String            error;

  const CartListResult._({required this.success, this.items = const [], this.error = ''});

  factory CartListResult.success(List<CartItemModel> items) =>
      CartListResult._(success: true, items: items);
  factory CartListResult.error(String msg) =>
      CartListResult._(success: false, error: msg);
}
