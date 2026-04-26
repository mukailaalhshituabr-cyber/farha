// lib/data/repositories/measurement_repository.dart
import '../models/measurement_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'product_repository.dart' show ListResult;

class MeasurementRepository {
  final ApiClient _api;
  const MeasurementRepository(this._api);

  Future<ListResult<MeasurementModel>> getProfiles() async {
    final res = await _api.get(ApiConstants.measurementList);
    if (!res.success) return ListResult.error(res.message);
    final data  = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => MeasurementModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ListResult.success(items: items, total: items.length);
  }

  Future<ApiResponse> create(Map<String, dynamic> data) =>
      _api.post(ApiConstants.measurementCreate, data: data);

  Future<ApiResponse> update(String id, Map<String, dynamic> data) =>
      _api.post('${ApiConstants.measurementUpdate}?id=$id', data: data);

  Future<ApiResponse> delete(String id) =>
      _api.delete('${ApiConstants.measurementDelete}?id=$id');
}
