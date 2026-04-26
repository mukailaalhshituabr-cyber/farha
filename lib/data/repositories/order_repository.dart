// lib/data/repositories/order_repository.dart
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiClient _api;
  const OrderRepository(this._api);

  Future<OrderListResult> getOrders({
    String? status,
    int page  = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(ApiConstants.orderList, params: {
      if (status != null) 'status': status,
      'page': page, 'limit': limit,
    });
    if (!res.success) return OrderListResult.error(res.message);
    final data       = res.data as Map<String, dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    final resTotal      = (pagination['total'] as num?)?.toInt() ?? 0;
    final resPage       = (pagination['page'] as num?)?.toInt() ?? 1;
    final resTotalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;
    return OrderListResult.success(
      items: (data['orders'] as List<dynamic>? ?? [])
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total:   resTotal,
      hasMore: resPage < resTotalPages,
    );
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final res = await _api.get(ApiConstants.orderDetail,
        params: {'id': orderId});
    if (!res.success) return null;
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ApiResponse> createOrder(Map<String, dynamic> data) =>
      _api.post(ApiConstants.orderCreate, data: data);

  Future<ApiResponse> updateStatus(String orderId, String status) =>
      _api.post(
          '${ApiConstants.orderUpdateStatus}?id=${Uri.encodeComponent(orderId)}',
          data: {'status': status});

  Future<ApiResponse> cancelOrder(String orderId, String reason) =>
      _api.post(
          '${ApiConstants.orderCancel}?id=${Uri.encodeComponent(orderId)}',
          data: {'cancel_reason': reason});
}

class OrderListResult {
  final bool         success;
  final List<OrderModel> items;
  final int          total;
  final bool         hasMore;
  final String       error;

  const OrderListResult._({
    required this.success,
    this.items   = const [],
    this.total   = 0,
    this.hasMore = false,
    this.error   = '',
  });

  factory OrderListResult.success({
    required List<OrderModel> items,
    required int total,
    bool hasMore = false,
  }) => OrderListResult._(success: true, items: items, total: total, hasMore: hasMore);

  factory OrderListResult.error(String msg) =>
      OrderListResult._(success: false, error: msg);
}
