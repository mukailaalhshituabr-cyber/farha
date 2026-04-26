// lib/data/models/order_model.dart

class OrderModel {
  final String  id;
  final String  referenceNumber;
  final String  customerId;
  final String  customerName;
  final String  tailorId;
  final String  tailorName;
  final String  shopName;
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final String  orderType;   // 'ready_made' | 'custom'
  final String  status;
  final String? size;
  final int     quantity;
  final double  totalAmount;
  final double  depositAmount;
  final double  paidAmount;
  final String  currency;
  final String? specialInstructions;
  final String? designReferenceUrl;
  final String? cancelReason;
  final String? estimatedCompletion;
  final String? shopLocation;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.referenceNumber,
    required this.customerId,
    required this.customerName,
    required this.tailorId,
    required this.tailorName,
    required this.shopName,
    this.productId,
    this.productName,
    this.productImageUrl,
    required this.orderType,
    required this.status,
    this.size,
    this.quantity        = 1,
    required this.totalAmount,
    this.depositAmount   = 0,
    this.paidAmount      = 0,
    this.currency        = 'CFA',
    this.specialInstructions,
    this.designReferenceUrl,
    this.cancelReason,
    this.estimatedCompletion,
    this.shopLocation,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  double get balanceDue => totalAmount - paidAmount;
  bool   get isFullyPaid => paidAmount >= totalAmount;
  bool   get isActive    => !['delivered','cancelled'].contains(status);
  bool   get isCancelled => status == 'cancelled';
  bool   get isDelivered => status == 'delivered';
  bool   get isCustom    => orderType == 'custom';

  int get progressPercent {
    const steps = ['pending','confirmed','cutting','sewing','ready','delivered'];
    final i = steps.indexOf(status);
    if (i < 0) return 0;
    return ((i / (steps.length - 1)) * 100).round();
  }

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id:                  j['id'].toString(),
    referenceNumber:     j['reference_number'] as String,
    customerId:          j['customer_id'].toString(),
    customerName:        j['customer_name'] as String? ?? '',
    tailorId:            j['tailor_id'].toString(),
    tailorName:          j['tailor_name'] as String? ?? '',
    shopName:            j['shop_name'] as String? ?? '',
    productId:           j['product_id']?.toString(),
    productName:         j['product_name'] as String?,
    productImageUrl:     j['product_image_url'] as String?,
    orderType:           j['order_type'] as String,
    status:              j['status'] as String,
    size:                j['size'] as String?,
    quantity:            j['quantity'] as int? ?? 1,
    totalAmount:         double.tryParse(j['total_amount'].toString()) ?? 0,
    depositAmount:       double.tryParse(j['deposit_amount'].toString()) ?? 0,
    paidAmount:          double.tryParse(j['paid_amount'].toString()) ?? 0,
    currency:            j['currency'] as String? ?? 'CFA',
    specialInstructions: j['special_instructions'] as String?,
    designReferenceUrl:  j['design_reference_url'] as String?,
    cancelReason:        j['cancel_reason'] as String?,
    estimatedCompletion: j['estimated_completion'] as String?,
    shopLocation:        j['shop_location'] as String?,
    latitude:            j['latitude']  != null ? double.tryParse(j['latitude'].toString())  : null,
    longitude:           j['longitude'] != null ? double.tryParse(j['longitude'].toString()) : null,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}
