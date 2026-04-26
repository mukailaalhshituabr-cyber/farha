// lib/data/models/wishlist_model.dart

class WishlistItemModel {
  final String  id;
  final String  productId;
  final String  productName;
  final double  price;
  final String  currency;
  final String? productImageUrl;
  final String? tailorName;
  final double  rating;
  final bool    isAvailable;
  final DateTime addedAt;

  const WishlistItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    this.currency        = 'CFA',
    this.productImageUrl,
    this.tailorName,
    this.rating          = 0,
    this.isAvailable     = true,
    required this.addedAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> j) => WishlistItemModel(
    id:              j['id'].toString(),
    productId:       j['product_id'].toString(),
    productName:     j['name'] as String? ?? j['product_name'] as String? ?? '',
    price:           double.tryParse((j['base_price'] ?? j['price'])?.toString() ?? '0') ?? 0,
    currency:        j['currency'] as String? ?? 'CFA',
    productImageUrl: j['main_image_url'] as String? ?? j['product_image_url'] as String?,
    tailorName:      j['tailor_name'] as String?,
    rating:          double.tryParse((j['rating'] ?? '0').toString()) ?? 0,
    isAvailable:     j['is_available'] == 1 || j['is_available'] == true,
    addedAt:         DateTime.tryParse(j['added_at'] as String? ?? j['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
