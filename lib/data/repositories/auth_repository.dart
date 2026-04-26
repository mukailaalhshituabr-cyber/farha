// lib/data/repositories/auth_repository.dart
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../services/local_storage_service.dart';

class AuthRepository {
  final ApiClient            _api;
  final LocalStorageService  _storage;

  const AuthRepository(this._api, this._storage);

  // ── Register customer ───────────────────────────────────────────────────
  Future<ApiResponse> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String gender,
    required String password,
    required String passwordConfirmation,
    required String language,
    required bool   termsAccepted,
  }) {
    return _api.post(ApiConstants.registerCustomer, data: {
      'first_name': firstName,
      'last_name':  lastName,
      'email':                  email,
      'phone':                  phone,
      'gender':                 gender,
      'password':               password,
      'password_confirmation':  passwordConfirmation,
      'language':               language,
      'terms_accepted':         termsAccepted,
    });
  }

  // ── Register tailor ─────────────────────────────────────────────────────
  Future<ApiResponse> registerTailor({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String gender,
    required String password,
    required String passwordConfirmation,
    required String language,
    required String shopName,
    required String shopLocation,
    required int    yearsExperience,
    required String experienceLevel,
    String?         bio,
    required bool   termsAccepted,
  }) {
    return _api.post(ApiConstants.registerTailor, data: {
      'first_name': firstName,
      'last_name':  lastName,
      'email':                  email,
      'phone':                  phone,
      'gender':                 gender,
      'password':               password,
      'password_confirmation':  passwordConfirmation,
      'language':               language,
      'shop_name':              shopName,
      'shop_location':          shopLocation,
      'years_experience':       yearsExperience,
      'experience_level':       experienceLevel,
      if (bio != null) 'bio':   bio,
      'terms_accepted':         termsAccepted,
    });
  }

  // ── Login ───────────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String identifier,
    required String password,
    String?         fcmToken,
  }) async {
    final res = await _api.post(ApiConstants.login, data: {
      'identifier': identifier,
      'password':   password,
      if (fcmToken != null) 'fcm_token': fcmToken,
    });

    if (!res.success) {
      return AuthResult.failure(res.message,
        emailNotVerified: res.data?['email_verified'] == false,
        email: res.data?['email'],
      );
    }

    final authData = AuthResponse.fromJson(res.data as Map<String, dynamic>);

    // Persist session securely
    await _storage.saveTokens(
      accessToken:  authData.accessToken,
      refreshToken: authData.refreshToken,
    );
    await _storage.saveSession(
      userId:       authData.user.id,
      userType:     authData.user.userType,
      firstName:    authData.user.firstName,
      lastName:     authData.user.lastName,
      email:        authData.user.email,
      language:     authData.user.language,
      profilePhoto: authData.user.profilePhoto,
    );
    await _storage.saveUser(authData.user);

    return AuthResult.success(authData.user);
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      await _api.post(ApiConstants.logout, data: {'refresh_token': refreshToken});
    }
    await _storage.clearAll();
  }

  // ── Resend verification email ─────────────────────────────────────────
  Future<ApiResponse> resendVerification(String email) =>
      _api.post(ApiConstants.verifyEmail, data: {'email': email});

  // ── Forgot password ───────────────────────────────────────────────────
  Future<ApiResponse> forgotPassword(String email) =>
      _api.post(ApiConstants.forgotPassword, data: {'email': email});

  // ── Verify OTP ───────────────────────────────────────────────────────
  Future<ApiResponse> verifyOtp({required String email, required String otp}) =>
      _api.post(ApiConstants.verifyOtp, data: {'email': email, 'otp': otp});

  // ── Reset password ────────────────────────────────────────────────────
  Future<ApiResponse> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) => _api.post(ApiConstants.resetPassword, data: {
    'reset_token':            resetToken,
    'password':               password,
    'password_confirmation':  passwordConfirmation,
  });

  // ── Google Sign-In ────────────────────────────────────────────────────
  /// Sends the Google ID token to the backend.
  /// Backend either finds the existing user or creates a new one.
  /// Returns [AuthResult.success] or [AuthResult.needsRegistration] (new user).
  Future<AuthResult> signInWithGoogle({
    required String idToken,
    String? userType, // 'customer' | 'tailor' — only needed for new users
  }) async {
    final res = await _api.post(ApiConstants.googleAuth, data: {
      'id_token':  idToken,
      if (userType != null) 'user_type': userType,
    });

    if (!res.success) {
      // Backend signals that this Google account is not registered yet
      if (res.data is Map &&
          (res.data as Map)['needs_registration'] == true) {
        return AuthResult.needsRegistration(
            email: (res.data as Map)['email'] as String?);
      }
      return AuthResult.failure(res.message);
    }

    final authData =
        AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await _storage.saveTokens(
      accessToken:  authData.accessToken,
      refreshToken: authData.refreshToken,
    );
    await _storage.saveSession(
      userId:       authData.user.id,
      userType:     authData.user.userType,
      firstName:    authData.user.firstName,
      lastName:     authData.user.lastName,
      email:        authData.user.email,
      language:     authData.user.language,
      profilePhoto: authData.user.profilePhoto,
    );
    await _storage.saveUser(authData.user);
    return AuthResult.success(authData.user);
  }

  // ── Update profile ────────────────────────────────────────────────────
  Future<ApiResponse> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? shopName,
    String? shopLocation,
    String? bio,
  }) => _api.post(ApiConstants.profile, data: {
    if (firstName    != null) 'first_name':    firstName,
    if (lastName     != null) 'last_name':     lastName,
    if (phone        != null) 'phone':         phone,
    if (shopName     != null) 'shop_name':     shopName,
    if (shopLocation != null) 'shop_location': shopLocation,
    if (bio          != null) 'bio':           bio,
  });

  // ── Persist full user locally ─────────────────────────────────────────
  Future<void> saveUser(UserModel user) => _storage.saveUser(user);

  // ── Fetch fresh user from server ──────────────────────────────────────
  Future<UserModel?> getMe() async {
    try {
      final res = await _api.get(ApiConstants.profile);
      if (!res.success || res.data == null) return null;
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Restore session ───────────────────────────────────────────────────
  Future<UserModel?> restoreSession() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    // Prefer the full JSON saved after last login/update
    final saved = await _storage.getSavedUser();
    if (saved != null) return saved;

    // Fallback: reconstruct from the older minimal session fields
    final session = await _storage.getSession();
    if (session == null) return null;
    final fullName  = (session['full_name'] as String? ?? '').trim();
    final nameParts = fullName.split(' ');
    return UserModel(
      id:           session['user_id']       as String? ?? '',
      firstName:    nameParts.isNotEmpty ? nameParts.first : '',
      lastName:     nameParts.length > 1  ? nameParts.sublist(1).join(' ') : '',
      email:        session['email']         as String? ?? '',
      userType:     session['user_type']     as String? ?? 'customer',
      language:     session['language']      as String? ?? 'en',
      profilePhoto: session['profile_photo'] as String?,
    );
  }
}

// ── Result wrapper ────────────────────────────────────────────────────────
class AuthResult {
  final bool       success;
  final UserModel? user;
  final String     message;
  final bool       emailNotVerified;
  final bool       needsRegistration;
  final String?    email;

  const AuthResult._({
    required this.success,
    this.user,
    required this.message,
    this.emailNotVerified  = false,
    this.needsRegistration = false,
    this.email,
  });

  factory AuthResult.success(UserModel user) =>
      AuthResult._(success: true, user: user, message: 'Login successful');

  factory AuthResult.failure(String message,
          {bool emailNotVerified = false, String? email}) =>
      AuthResult._(
          success:          false,
          message:          message,
          emailNotVerified: emailNotVerified,
          email:            email);

  factory AuthResult.needsRegistration({String? email}) =>
      AuthResult._(
          success:           false,
          message:           'needs_registration',
          needsRegistration: true,
          email:             email);
}
