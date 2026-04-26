// lib/data/models/payment_model.dart

class PaymentModel {
  final String  id;
  final String  orderId;
  final double  amount;
  final String  currency;
  final String  paymentMethod;
  final String  paymentType;    // 'deposit' | 'full' | 'balance'
  final String? transactionId;
  final String  status;         // 'pending' | 'success' | 'failed' | 'refunded'
  final String? country;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    this.currency       = 'CFA',
    required this.paymentMethod,
    required this.paymentType,
    this.transactionId,
    required this.status,
    this.country,
    required this.createdAt,
  });

  bool get isSuccess  => status == 'success';
  bool get isPending  => status == 'pending';
  bool get isFailed   => status == 'failed';
  bool get isRefunded => status == 'refunded';

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id:            j['id'].toString(),
    orderId:       j['order_id'].toString(),
    amount:        double.tryParse(j['amount'].toString()) ?? 0,
    currency:      j['currency'] as String? ?? 'CFA',
    paymentMethod: j['payment_method'] as String,
    paymentType:   j['payment_type'] as String,
    transactionId: j['transaction_id'] as String?,
    status:        j['status'] as String,
    country:       j['country'] as String?,
    createdAt:     DateTime.parse(j['created_at'] as String),
  );
}
