// lib/data/models/cart_model.dart

class CartItemModel {
  final String  id;
  final String  customerId;
  final String  productId;
  final String  tailorId;
  final String  productName;
  final double  price;
  final String  currency;
  final String? productImageUrl;
  final String? tailorName;
  final String? shopName;
  final int     quantity;
  final String? size;
  final bool    isAvailable;

  const CartItemModel({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.tailorId,
    required this.productName,
    required this.price,
    this.currency        = 'CFA',
    this.productImageUrl,
    this.tailorName,
    this.shopName,
    required this.quantity,
    this.size,
    this.isAvailable     = true,
  });

  double get subtotal => price * quantity;

  CartItemModel copyWith({int? quantity}) => CartItemModel(
    id:              id,
    customerId:      customerId,
    productId:       productId,
    tailorId:        tailorId,
    productName:     productName,
    price:           price,
    currency:        currency,
    productImageUrl: productImageUrl,
    tailorName:      tailorName,
    shopName:        shopName,
    quantity:        quantity ?? this.quantity,
    size:            size,
    isAvailable:     isAvailable,
  );

  factory CartItemModel.fromJson(Map<String, dynamic> j) => CartItemModel(
    id:              j['id'].toString(),
    customerId:      j['customer_id']?.toString() ?? '',
    productId:       j['product_id'].toString(),
    tailorId:        j['tailor_id']?.toString() ?? '',
    productName:     j['name'] as String? ?? j['product_name'] as String? ?? '',
    price:           double.tryParse((j['base_price'] ?? j['price']).toString()) ?? 0,
    currency:        j['currency'] as String? ?? 'CFA',
    productImageUrl: j['main_image_url'] as String? ?? j['product_image_url'] as String?,
    tailorName:      j['tailor_name'] as String?,
    shopName:        j['shop_name'] as String?,
    quantity:        j['quantity'] as int? ?? 1,
    size:            j['size'] as String?,
    isAvailable:     j['is_available'] == null || j['is_available'] == 1 || j['is_available'] == true,
  );
}
