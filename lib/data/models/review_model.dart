// lib/data/models/review_model.dart

class ReviewModel {
  final String  id;
  final int     rating;
  final String? comment;
  final String  customerName;
  final String? customerPhoto;
  final String? productId;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.customerName,
    this.customerPhoto,
    this.productId,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
    id:            j['id'].toString(),
    rating:        (j['rating'] as num).toInt(),
    comment:       j['comment'] as String?,
    customerName:  j['customer_name'] as String? ?? 'Customer',
    customerPhoto: j['profile_photo'] as String?,
    productId:     j['product_id']?.toString(),
    createdAt:     DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
