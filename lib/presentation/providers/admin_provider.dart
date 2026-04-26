// lib/presentation/providers/admin_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import 'auth_provider.dart' show apiClientProvider;

// ── Admin model ───────────────────────────────────────────────────────────────
class AdminModel {
  final String id;
  final String name;
  final String email;
  final String role;

  const AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AdminModel.fromJson(Map<String, dynamic> j) => AdminModel(
    id:    j['id']    as String,
    name:  j['name']  as String,
    email: j['email'] as String,
    role:  j['role']  as String,
  );

  bool get isSuperAdmin => role == 'super_admin';
}

// ── Admin auth state ──────────────────────────────────────────────────────────
class AdminAuthState {
  final AdminModel? admin;
  final bool        isLoading;
  final String?     error;

  const AdminAuthState({
    this.admin,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => admin != null;
}

// ── Admin auth notifier ───────────────────────────────────────────────────────
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final ApiClient            _api;
  final FlutterSecureStorage _storage;
  static const _tokenKey     = 'admin_token';
  static const _adminDataKey = 'admin_data';

  AdminAuthNotifier(this._api)
      : _storage = const FlutterSecureStorage(),
        super(const AdminAuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token     = await _storage.read(key: _tokenKey);
    final adminJson = await _storage.read(key: _adminDataKey);
    if (token != null && adminJson != null) {
      try {
        final admin = AdminModel.fromJson(
            jsonDecode(adminJson) as Map<String, dynamic>);
        _api.setAdminToken(token);
        state = AdminAuthState(admin: admin);
      } catch (_) {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _adminDataKey);
      }
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AdminAuthState(isLoading: true);

    // Login does NOT need admin token — clear it first so the user JWT isn't sent
    _api.clearAdminToken();

    final res = await _api.post(
      ApiConstants.adminLogin,
      data: {'email': email.trim(), 'password': password},
    );
    if (!res.success) {
      state = AdminAuthState(error: res.message);
      return res.message;
    }
    final data  = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final admin = AdminModel.fromJson(data['admin'] as Map<String, dynamic>);
    await _storage.write(key: _tokenKey,     value: token);
    await _storage.write(key: _adminDataKey, value: jsonEncode(data['admin']));
    _api.setAdminToken(token);
    state = AdminAuthState(admin: admin);
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _adminDataKey);
    _api.clearAdminToken();
    state = const AdminAuthState();
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) =>
        AdminAuthNotifier(ref.watch(apiClientProvider)));

// ── Dashboard stats ───────────────────────────────────────────────────────────
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiConstants.adminStats);
  if (!res.success) throw Exception(res.message);
  return res.data as Map<String, dynamic>;
});
