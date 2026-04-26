// lib/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateNotifier, StateNotifierProvider;
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/local_storage_service.dart';
import '../../core/network/api_client.dart';

// ── Service providers ──────────────────────────────────────────────────────
final localStorageProvider = Provider<LocalStorageService>(
    (ref) => LocalStorageService());

final apiClientProvider = Provider<ApiClient>((ref) =>
    ApiClient(ref.watch(localStorageProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepository(
      ref.watch(apiClientProvider),
      ref.watch(localStorageProvider),
    ));

// ── Auth status ────────────────────────────────────────────────────────────
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final bool       isLoading;

  const AuthState({
    this.status    = AuthStatus.initial,
    this.user,
    this.isLoading = false,
  });

  bool get isAuthenticated   => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    bool?       isLoading,
  }) =>
      AuthState(
        status:    status    ?? this.status,
        user:      user      ?? this.user,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _restore();
  }

  // ── Restore saved session on app start ────────────────────────────────
  Future<void> _restore() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.restoreSession();
      state = AuthState(
        status:    user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user:      user,
        isLoading: false,
      );
      // Background-refresh from server so all fields stay current
      if (user != null) _refreshFromServer();
    } catch (_) {
      state = const AuthState(
          status: AuthStatus.unauthenticated, isLoading: false);
    }
  }

  // Silently fetch fresh user data and update state + storage.
  void _refreshFromServer() {
    _repo.getMe().then((fresh) {
      if (fresh != null && state.isAuthenticated) {
        state = state.copyWith(user: fresh);
        _repo.saveUser(fresh); // fire-and-forget
      }
    }).catchError((_) {});
  }

  // ── Login ──────────────────────────────────────────────────────────────
  Future<AuthLoginResult> login({
    required String identifier,
    required String password,
    String?         fcmToken,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _repo.login(
        identifier: identifier,
        password:   password,
        fcmToken:   fcmToken,
      );

      if (result.success && result.user != null) {
        // Set authenticated FIRST — router will react to this
        state = AuthState(
          status:    AuthStatus.authenticated,
          user:      result.user,
          isLoading: false,
        );
        return AuthLoginResult.success(result.user!);
      }

      // Login failed — stay unauthenticated
      state = const AuthState(
          status: AuthStatus.unauthenticated, isLoading: false);

      return AuthLoginResult.failure(
        result.message,
        emailNotVerified: result.emailNotVerified,
        email:            result.email,
        isNetworkError:   false,
      );
    } catch (e) {
      state = const AuthState(
          status: AuthStatus.unauthenticated, isLoading: false);

      return AuthLoginResult.failure(
        'Connection error. Please check your internet connection and try again.',
        isNetworkError: true,
      );
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.logout();
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
    _repo.saveUser(user); // persist so photo/changes survive app restart
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────
  /// Call with the Google ID token obtained from GoogleSignIn.
  /// [userType] is only needed when a new account must be created.
  Future<AuthLoginResult> signInWithGoogle({
    required String idToken,
    String?         userType,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.signInWithGoogle(
        idToken:  idToken,
        userType: userType,
      );

      if (result.success && result.user != null) {
        state = AuthState(
          status:    AuthStatus.authenticated,
          user:      result.user,
          isLoading: false,
        );
        return AuthLoginResult.success(result.user!);
      }

      state = const AuthState(
          status: AuthStatus.unauthenticated, isLoading: false);

      if (result.needsRegistration) {
        return AuthLoginResult.failure(
          'needs_registration',
          needsRegistration: true,
          email: result.email,
        );
      }

      return AuthLoginResult.failure(result.message);
    } catch (e) {
      state = const AuthState(
          status: AuthStatus.unauthenticated, isLoading: false);
      return AuthLoginResult.failure(
          'Could not sign in with Google. Try again.',
          isNetworkError: true);
    }
  }

  // ── Update profile fields ──────────────────────────────────────────────
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? shopName,
    String? shopLocation,
    String? bio,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repo.updateProfile(
        firstName:    firstName,
        lastName:     lastName,
        phone:        phone,
        shopName:     shopName,
        shopLocation: shopLocation,
        bio:          bio,
      );
      state = state.copyWith(isLoading: false);
      if (res.success) {
        final fresh = await _repo.getMe();
        if (fresh != null) {
          state = state.copyWith(user: fresh);
          await _repo.saveUser(fresh);
        }
      }
      return res.success;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
        (ref) => AuthNotifier(ref.watch(authRepositoryProvider)));

// ── Login result ───────────────────────────────────────────────────────────
class AuthLoginResult {
  final bool       success;
  final UserModel? user;
  final String     message;
  final bool       emailNotVerified;
  final bool       needsRegistration;
  final String?    email;
  final bool       isNetworkError;

  const AuthLoginResult._({
    required this.success,
    this.user,
    this.message           = '',
    this.emailNotVerified  = false,
    this.needsRegistration = false,
    this.email,
    this.isNetworkError    = false,
  });

  factory AuthLoginResult.success(UserModel user) =>
      AuthLoginResult._(success: true, user: user);

  factory AuthLoginResult.failure(
    String message, {
    bool    emailNotVerified  = false,
    bool    needsRegistration = false,
    String? email,
    bool    isNetworkError    = false,
  }) =>
      AuthLoginResult._(
        success:           false,
        message:           message,
        emailNotVerified:  emailNotVerified,
        needsRegistration: needsRegistration,
        email:             email,
        isNetworkError:    isNetworkError,
      );
}
