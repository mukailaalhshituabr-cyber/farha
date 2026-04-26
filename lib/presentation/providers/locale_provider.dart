// lib/presentation/providers/locale_provider.dart
import 'dart:ui';
import 'package:flutter_riverpod/legacy.dart' show StateNotifier, StateNotifierProvider;
import '../../data/services/local_storage_service.dart';
import 'auth_provider.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _storage;

  LocaleNotifier(this._storage) : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final lang = await _storage.getLanguage();
    state = Locale(lang);
  }

  Future<void> setLocale(Locale locale) async {
    await _storage.setLanguage(locale.languageCode);
    state = locale;
  }

  Future<void> setLanguage(String langCode) =>
      setLocale(Locale(langCode));
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>(
        (ref) => LocaleNotifier(ref.watch(localStorageProvider)));
