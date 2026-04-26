// lib/data/models/product_model.dart

class ProductImage {
  final String id;
  final String imageUrl;
  final bool   isMain;

  const ProductImage({required this.id, required this.imageUrl, required this.isMain});

  factory ProductImage.fromJson(Map<String, dynamic> j) => ProductImage(
    id:       j['id'].toString(),
    imageUrl: j['image_url'] as String,
    isMain:   j['is_main'] == 1 || j['is_main'] == true,
  );
}

class ProductModel {
  final String       id;
  final String       tailorId;
  final String       tailorName;
  final String       categoryId;
  final String       categoryName;
  final String       name;
  final String?      description;
  final double       basePrice;
  final String       currency;
  final int          stockQuantity;
  final bool         allowsCustom;
  final bool         isAvailable;
  final bool         isDraft;
  final double       rating;
  final int          totalReviews;
  final int          totalSales;
  final List<ProductImage> images;
  final List<String> availableSizes;
  final String?      mainImageUrl;
  final DateTime?    createdAt;

  const ProductModel({
    required this.id,
    required this.tailorId,
    required this.tailorName,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.description,
    required this.basePrice,
    this.currency      = 'CFA',
    required this.stockQuantity,
    this.allowsCustom  = false,
    this.isAvailable   = true,
    this.isDraft       = false,
    this.rating        = 0,
    this.totalReviews  = 0,
    this.totalSales    = 0,
    this.images        = const [],
    this.availableSizes= const [],
    this.mainImageUrl,
    this.createdAt,
  });

  String? get displayImage =>
      mainImageUrl ??
      images.where((i) => i.isMain).map((i) => i.imageUrl).firstOrNull ??
      images.firstOrNull?.imageUrl;

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
    id:             j['id'].toString(),
    tailorId:       j['tailor_id'].toString(),
    tailorName:     j['tailor_name'] as String? ?? '',
    categoryId:     j['category_id'].toString(),
    categoryName:   j['category_name'] as String? ?? '',
    name:           j['name'] as String,
    description:    j['description'] as String?,
    basePrice:      double.tryParse(j['base_price'].toString()) ?? 0,
    currency:       j['currency'] as String? ?? 'CFA',
    stockQuantity:  j['stock_quantity'] as int? ?? 0,
    allowsCustom:   j['allows_custom'] == 1 || j['allows_custom'] == true,
    isAvailable:    j['is_available'] == 1 || j['is_available'] == true,
    isDraft:        j['is_draft'] == 1 || j['is_draft'] == true,
    rating:         double.tryParse(j['rating'].toString()) ?? 0,
    totalReviews:   j['total_reviews'] as int? ?? 0,
    totalSales:     j['total_sales'] as int? ?? 0,
    mainImageUrl:   j['main_image_url'] as String?,
    images: (j['images'] as List<dynamic>?)
        ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    availableSizes: (j['available_sizes'] as List<dynamic>?)
        ?.map((e) => e.toString()).toList() ?? [],
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'tailor_id': tailorId, 'name': name,
    'base_price': basePrice, 'category_id': categoryId,
    'stock_quantity': stockQuantity, 'allows_custom': allowsCustom,
    'is_available': isAvailable, 'is_draft': isDraft,
    if (description != null) 'description': description,
  };
}
