// lib/data/repositories/payment_repository.dart
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final ApiClient _api;
  const PaymentRepository(this._api);

  Future<ApiResponse> initiate({
    required int    orderId,
    required double amount,
    required String paymentMethod,
    required String paymentType,
    String?         country,
    String?         paymentPhone,
  }) =>
      _api.post(ApiConstants.paymentInitiate, data: {
        'order_id':       orderId,
        'amount':         amount,
        'payment_method': paymentMethod,
        'payment_type':   paymentType,
        if (country != null)      'country':       country,
        if (paymentPhone != null) 'payment_phone': paymentPhone,
      });

  Future<ApiResponse> verify(String transactionId) =>
      _api.post(ApiConstants.paymentVerify,
          data: {'transaction_id': transactionId});

  Future<PaymentHistoryResult> history() async {
    final res = await _api.get(ApiConstants.paymentHistory);
    if (!res.success) return PaymentHistoryResult.error(res.message);
    final items = (res.data as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaymentHistoryResult.success(items);
  }
}

class PaymentHistoryResult {
  final bool               success;
  final List<PaymentModel> items;
  final String             error;

  const PaymentHistoryResult._({required this.success, this.items = const [], this.error = ''});

  factory PaymentHistoryResult.success(List<PaymentModel> items) =>
      PaymentHistoryResult._(success: true, items: items);
  factory PaymentHistoryResult.error(String msg) =>
      PaymentHistoryResult._(success: false, error: msg);
}
