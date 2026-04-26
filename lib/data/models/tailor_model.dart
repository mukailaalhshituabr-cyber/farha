// lib/data/models/tailor_model.dart

class TailorModel {
  final String  id;
  final String  userId;
  final String  fullName;
  final String  shopName;
  final String? bio;
  final String? shopLocation;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final int     yearsExperience;
  final String  experienceLevel;
  final bool    isAvailable;
  final bool    isVerified;
  final double  rating;
  final int     totalReviews;
  final int     totalOrders;
  final String? profilePhoto;
  final String? email;
  final String? phone;
  final Map<String, String>? businessHours;

  const TailorModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.shopName,
    this.bio,
    this.shopLocation,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.yearsExperience = 0,
    this.experienceLevel = 'apprentice',
    this.isAvailable     = true,
    this.isVerified      = false,
    this.rating          = 0,
    this.totalReviews    = 0,
    this.totalOrders     = 0,
    this.profilePhoto,
    this.email,
    this.phone,
    this.businessHours,
  });

  factory TailorModel.fromJson(Map<String, dynamic> j) => TailorModel(
    id:              j['id'].toString(),
    userId:          j['user_id'].toString(),
    fullName:        j['full_name'] as String? ?? '',
    shopName:        j['shop_name'] as String,
    bio:             j['bio'] as String?,
    shopLocation:    j['shop_location'] as String?,
    latitude:        j['latitude'] != null ? double.tryParse(j['latitude'].toString()) : null,
    longitude:       j['longitude'] != null ? double.tryParse(j['longitude'].toString()) : null,
    distanceKm:      j['distance_km'] != null ? double.tryParse(j['distance_km'].toString()) : null,
    yearsExperience: j['years_experience'] as int? ?? 0,
    experienceLevel: j['experience_level'] as String? ?? 'apprentice',
    isAvailable:     j['is_available'] == 1 || j['is_available'] == true,
    isVerified:      j['is_verified_tailor'] == 1 || j['is_verified_tailor'] == true,
    rating:          double.tryParse(j['rating'].toString()) ?? 0,
    totalReviews:    j['total_reviews'] as int? ?? 0,
    totalOrders:     j['total_orders'] as int? ?? 0,
    profilePhoto:    j['profile_photo'] as String?,
    email:           j['email'] as String?,
    phone:           j['phone'] as String?,
  );
}
