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
  static const _trackingKey = 'rad.settings.trackingProtection';
  static const _httpsFirstKey = 'rad.settings.httpsFirst';
  static const _blockPopupsKey = 'rad.settings.blockPopups';
  static const _dataSaverKey = 'rad.settings.dataSaver';

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
      trackingProtection: _readEnum(
        prefs.getString(_trackingKey),
        RadTrackingProtection.values,
        RadTrackingProtection.standard,
      ),
      httpsFirst: prefs.getBool(_httpsFirstKey) ?? true,
      blockPopups: prefs.getBool(_blockPopupsKey) ?? true,
      dataSaver: prefs.getBool(_dataSaverKey) ?? false,
    );
  }

  Future<void> setTheme(RadThemePreference value) async {
    state = state.copyWith(theme: value);
    await _setString(_themeKey, value.name);
  }

  Future<void> setSearchEngine(RadSearchEngine value) async {
    state = state.copyWith(searchEngine: value);
    await _setString(_searchEngineKey, value.name);
  }

  Future<void> setUiDensity(RadUiDensity value) async {
    state = state.copyWith(uiDensity: value);
    await _setString(_densityKey, value.name);
  }

  Future<void> setTrackingProtection(RadTrackingProtection value) async {
    state = state.copyWith(trackingProtection: value);
    await _setString(_trackingKey, value.name);
  }

  Future<void> setHttpsFirst(bool value) async {
    state = state.copyWith(httpsFirst: value);
    await _setBool(_httpsFirstKey, value);
  }

  Future<void> setBlockPopups(bool value) async {
    state = state.copyWith(blockPopups: value);
    await _setBool(_blockPopupsKey, value);
  }

  Future<void> setDataSaver(bool value) async {
    state = state.copyWith(dataSaver: value);
    await _setBool(_dataSaverKey, value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  T _readEnum<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }
}
