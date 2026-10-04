import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/app_settings.dart';

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  final controller = SettingsController();
  unawaited(controller.load());
  return controller;
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings());

  static const _themeKey = 'rad.settings.theme';
  static const _searchEngineKey = 'rad.settings.searchEngine';
  static const _densityKey = 'rad.settings.uiDensity';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      theme: _readEnum(
        prefs.getString(_themeKey),
        RadThemePreference.values,
        RadThemePreference.system,
      ),
      searchEngine: _readEnum(
        prefs.getString(_searchEngineKey),
        RadSearchEngine.values,
        RadSearchEngine.google,
      ),
      uiDensity: _readEnum(
        prefs.getString(_densityKey),
        RadUiDensity.values,
        RadUiDensity.comfortable,
      ),
    );
  }

  Future<void> setTheme(RadThemePreference value) async {
    state = state.copyWith(theme: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value.name);
  }

  Future<void> setSearchEngine(RadSearchEngine value) async {
    state = state.copyWith(searchEngine: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchEngineKey, value.name);
  }

  Future<void> setUiDensity(RadUiDensity value) async {
    state = state.copyWith(uiDensity: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_densityKey, value.name);
  }

  T _readEnum<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }
}
