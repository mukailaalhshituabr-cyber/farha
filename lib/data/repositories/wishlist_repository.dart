// lib/data/repositories/wishlist_repository.dart
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/wishlist_model.dart';

class WishlistRepository {
  final ApiClient _api;
  const WishlistRepository(this._api);

  Future<WishlistResult> getWishlist() async {
    final res = await _api.get(ApiConstants.wishlistGet);
    if (!res.success) return WishlistResult.error(res.message);
    final data  = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return WishlistResult.success(items);
  }

  Future<ApiResponse> add(String productId) =>
      _api.post(ApiConstants.wishlistAdd, data: {'product_id': productId});

  Future<ApiResponse> remove(String productId) =>
      _api.delete(ApiConstants.wishlistRemove,
          params: {'product_id': productId});
}

class WishlistResult {
  final bool                   success;
  final List<WishlistItemModel> items;
  final String                 error;

  const WishlistResult._({required this.success, this.items = const [], this.error = ''});

  factory WishlistResult.success(List<WishlistItemModel> items) =>
      WishlistResult._(success: true, items: items);
  factory WishlistResult.error(String msg) =>
      WishlistResult._(success: false, error: msg);
}
