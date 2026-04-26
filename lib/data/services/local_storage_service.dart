// lib/data/services/local_storage_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

class LocalStorageService {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Keys ────────────────────────────────────────────────────────────────
  static const _kAccessToken  = 'farha_access_token';
  static const _kRefreshToken = 'farha_refresh_token';
  static const _kUserId       = 'farha_user_id';
  static const _kUserType     = 'farha_user_type';
  static const _kUserName     = 'farha_user_name';
  static const _kUserEmail    = 'farha_user_email';
  static const _kLanguage     = 'farha_language';
  static const _kOnboarded    = 'farha_onboarded';
  static const _kProfilePhoto = 'farha_profile_photo';
  static const _kUserJson     = 'farha_user_json';

  // ── Tokens (secure storage) ──────────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secure.write(key: _kAccessToken,  value: accessToken),
      _secure.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken()  => _secure.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _secure.read(key: _kRefreshToken);

  Future<void> clearTokens() async {
    await Future.wait([
      _secure.delete(key: _kAccessToken),
      _secure.delete(key: _kRefreshToken),
    ]);
  }

  // ── Session data (shared preferences — non-sensitive) ───────────────────
  Future<void> saveSession({
    required String userId,
    required String userType,
    required String firstName,
    required String lastName,
    required String email,
    required String language,
    String?         profilePhoto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kUserId,       userId),
      prefs.setString(_kUserType,     userType),
      prefs.setString(_kUserName,     '$firstName $lastName'),
      prefs.setString(_kUserEmail,    email),
      prefs.setString(_kLanguage,     language),
      if (profilePhoto != null)
        prefs.setString(_kProfilePhoto, profilePhoto),
    ]);
  }

  Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kUserId);
    if (userId == null) return null;
    return {
      'user_id':       userId,
      'user_type':     prefs.getString(_kUserType)     ?? '',
      'full_name':     prefs.getString(_kUserName)     ?? '',
      'email':         prefs.getString(_kUserEmail)    ?? '',
      'language':      prefs.getString(_kLanguage)     ?? 'en',
      'profile_photo': prefs.getString(_kProfilePhoto),
    };
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Full user JSON (persists all fields across restarts) ─────────────────
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserJson, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kUserJson);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguage) ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, lang);
  }

  Future<bool> hasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarded) ?? false;
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarded, true);
  }

  // ── Full clear (logout) ─────────────────────────────────────────────────
  Future<void> clearAll() async {
    await clearTokens();
    final prefs = await SharedPreferences.getInstance();
    // Keep language and onboarded flag — only clear session data
    await Future.wait([
      prefs.remove(_kUserId),
      prefs.remove(_kUserType),
      prefs.remove(_kUserName),
      prefs.remove(_kUserEmail),
      prefs.remove(_kProfilePhoto),
      prefs.remove(_kUserJson),
    ]);
  }
}
