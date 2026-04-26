// lib/data/models/user_model.dart

class UserModel {
  final String  id;
  final String  firstName;
  final String  lastName;
  final String  email;
  final String? phone;
  final String  userType;
  final String  language;
  final String? profilePhoto;
  final dynamic profile;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.userType,
    required this.language,
    this.profilePhoto,
    this.profile,
  });

  // Convenience getter — combines both for display
  String get fullName => '$firstName $lastName';

  bool get isCustomer => userType == 'customer';
  bool get isTailor   => userType == 'tailor';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    dynamic profile;
    if (json['user_type'] == 'customer' && json['profile'] != null) {
      profile = CustomerProfile.fromJson(json['profile'] as Map<String, dynamic>);
    } else if (json['user_type'] == 'tailor' && json['profile'] != null) {
      profile = TailorProfile.fromJson(json['profile'] as Map<String, dynamic>);
    }
    return UserModel(
      id:           json['id'].toString(),
      firstName:    json['first_name'] as String,
      lastName:     json['last_name'] as String,
      email:        json['email'] as String,
      phone:        json['phone'] as String?,
      userType:     json['user_type'] as String,
      language:     json['language'] as String? ?? 'en',
      profilePhoto: json['profile_photo'] as String?,
      profile:      profile,
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id':            id,
      'first_name':    firstName,
      'last_name':     lastName,
      'email':         email,
      'phone':         phone,
      'user_type':     userType,
      'language':      language,
      'profile_photo': profilePhoto,
    };
    if (profile is TailorProfile) {
      m['profile'] = (profile as TailorProfile).toJson();
    } else if (profile is CustomerProfile) {
      m['profile'] = (profile as CustomerProfile).toJson();
    }
    return m;
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? language,
    String? profilePhoto,
    dynamic profile,
  }) =>
      UserModel(
        id:           id,
        email:        email,
        userType:     userType,
        firstName:    firstName    ?? this.firstName,
        lastName:     lastName     ?? this.lastName,
        phone:        phone        ?? this.phone,
        language:     language     ?? this.language,
        profilePhoto: profilePhoto ?? this.profilePhoto,
        profile:      profile      ?? this.profile,
      );
}

// ── Customer profile ──────────────────────────────────────────────────────
class CustomerProfile {
  final String  id;
  final String? gender;

  const CustomerProfile({required this.id, this.gender});

  factory CustomerProfile.fromJson(Map<String, dynamic> j) =>
      CustomerProfile(id: j['id'].toString(), gender: j['gender'] as String?);

  Map<String, dynamic> toJson() => {'id': id, 'gender': gender};
}

// ── Tailor profile ────────────────────────────────────────────────────────
class TailorProfile {
  final String  id;
  final String  shopName;
  final String  experienceLevel;
  final double  rating;
  final bool    isVerified;

  const TailorProfile({
    required this.id,
    required this.shopName,
    required this.experienceLevel,
    required this.rating,
    required this.isVerified,
  });

  factory TailorProfile.fromJson(Map<String, dynamic> j) => TailorProfile(
    id:              j['id'].toString(),
    shopName:        j['shop_name'] as String,
    experienceLevel: j['experience_level'] as String? ?? 'apprentice',
    rating:          double.tryParse(j['rating'].toString()) ?? 0.0,
    isVerified:      j['is_verified_tailor'] == 1 || j['is_verified_tailor'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id':                 id,
    'shop_name':          shopName,
    'experience_level':   experienceLevel,
    'rating':             rating,
    'is_verified_tailor': isVerified,
  };
}

// ── Auth response ─────────────────────────────────────────────────────────
class AuthResponse {
  final String    accessToken;
  final String    refreshToken;
  final int       expiresIn;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken:  json['access_token']  as String,
    refreshToken: json['refresh_token'] as String,
    expiresIn:    json['expires_in']    as int,
    user:         UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );
}