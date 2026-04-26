// lib/data/repositories/review_repository.dart
import '../models/review_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class ReviewRepository {
  final ApiClient _api;
  const ReviewRepository(this._api);

  Future<ReviewListResult> getReviews({String? tailorId, String? productId}) async {
    final res = await _api.get(ApiConstants.reviewList, params: {
      if (tailorId  != null) 'tailor_id':  tailorId,
      if (productId != null) 'product_id': productId,
    });
    if (!res.success) return ReviewListResult.error(res.message);
    final data  = res.data as Map<String, dynamic>;
    final items = (data['reviews'] as List<dynamic>? ?? [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReviewListResult.success(items);
  }

  Future<ApiResponse> create({
    required String orderId,
    required int    rating,
    String?         comment,
  }) =>
      _api.post(ApiConstants.reviewCreate, data: {
        'order_id': orderId,
        'rating':   rating,
        if (comment != null) 'comment': comment,
      });
}

class ReviewListResult {
  final bool              success;
  final List<ReviewModel> items;
  final String            error;

  const ReviewListResult._({required this.success, this.items = const [], this.error = ''});

  factory ReviewListResult.success(List<ReviewModel> items) =>
      ReviewListResult._(success: true, items: items);
  factory ReviewListResult.error(String msg) =>
      ReviewListResult._(success: false, error: msg);
}
