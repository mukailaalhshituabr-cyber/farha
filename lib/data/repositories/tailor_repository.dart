// lib/data/repositories/tailor_repository.dart
import '../models/tailor_model.dart';
import '../models/review_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'product_repository.dart' show ListResult;

class TailorRepository {
  final ApiClient _api;
  const TailorRepository(this._api);

  Future<ListResult<TailorModel>> getTailors({
    String? filter,    // 'top_rated' | 'near_me' | '5_plus_years'
    double? latitude,
    double? longitude,
    String? query,
  }) async {
    final res = await _api.get(ApiConstants.tailorList, params: {
      if (filter != null)    'filter':    filter,
      if (latitude != null)  'lat':       latitude,
      if (longitude != null) 'lng':       longitude,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    if (!res.success) return ListResult.error(res.message);
    final data  = res.data as Map<String, dynamic>;
    final items = (data['tailors'] as List<dynamic>? ?? [])
        .map((e) => TailorModel.fromJson(e as Map<String, dynamic>)).toList();
    final total = (data['pagination'] as Map?)?['total'] as int? ?? items.length;
    return ListResult.success(items: items, total: total);
  }

  Future<TailorModel?> getTailorProfile(String tailorId) async {
    final res = await _api.get(ApiConstants.tailorProfile,
        params: {'id': tailorId});
    if (!res.success) return null;
    return TailorModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ListResult<ReviewModel>> getReviews(String tailorId) async {
    final res = await _api.get(ApiConstants.reviewList,
        params: {'tailor_id': tailorId});
    if (!res.success) return ListResult.error(res.message);
    final data = res.data as Map<String, dynamic>;
    final list = data['reviews'] as List<dynamic>? ?? [];
    final items = list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    final total = (data['pagination'] as Map?)?.containsKey('total') == true
        ? (data['pagination']['total'] as num).toInt() : items.length;
    return ListResult.success(items: items, total: total);
  }
}

