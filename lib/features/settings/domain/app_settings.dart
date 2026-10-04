import 'package:flutter/material.dart';

enum RadThemePreference { system, light, dark }
enum RadSearchEngine { google, bing, duckDuckGo }
enum RadUiDensity { comfortable, compact }
enum RadTrackingProtection { off, standard, strict }

class AppSettings {
  const AppSettings({
    this.theme = RadThemePreference.system,
    this.searchEngine = RadSearchEngine.google,
    this.uiDensity = RadUiDensity.comfortable,
    this.trackingProtection = RadTrackingProtection.standard,
    this.httpsFirst = true,
    this.blockPopups = true,
    this.dataSaver = false,
  });

  final RadThemePreference theme;
  final RadSearchEngine searchEngine;
  final RadUiDensity uiDensity;
  final RadTrackingProtection trackingProtection;
  final bool httpsFirst;
  final bool blockPopups;
  final bool dataSaver;

  ThemeMode get themeMode => switch (theme) {
        RadThemePreference.system => ThemeMode.system,
        RadThemePreference.light => ThemeMode.light,
        RadThemePreference.dark => ThemeMode.dark,
      };

  AppSettings copyWith({
    RadThemePreference? theme,
    RadSearchEngine? searchEngine,
    RadUiDensity? uiDensity,
    RadTrackingProtection? trackingProtection,
    bool? httpsFirst,
    bool? blockPopups,
    bool? dataSaver,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      searchEngine: searchEngine ?? this.searchEngine,
      uiDensity: uiDensity ?? this.uiDensity,
      trackingProtection: trackingProtection ?? this.trackingProtection,
      httpsFirst: httpsFirst ?? this.httpsFirst,
      blockPopups: blockPopups ?? this.blockPopups,
      dataSaver: dataSaver ?? this.dataSaver,
    );
  }
}

extension RadSearchEngineInfo on RadSearchEngine {
  String get title => switch (this) {
        RadSearchEngine.google => 'Google',
        RadSearchEngine.bing => 'Bing',
        RadSearchEngine.duckDuckGo => 'DuckDuckGo',
      };

  Uri searchUri(String query) => switch (this) {
        RadSearchEngine.google =>
          Uri.https('www.google.com', '/search', {'q': query}),
        RadSearchEngine.bing =>
          Uri.https('www.bing.com', '/search', {'q': query}),
        RadSearchEngine.duckDuckGo =>
          Uri.https('duckduckgo.com', '/', {'q': query}),
      };
}

extension RadTrackingProtectionInfo on RadTrackingProtection {
  String get title => switch (this) {
        RadTrackingProtection.off => 'خاموش',
        RadTrackingProtection.standard => 'استاندارد',
        RadTrackingProtection.strict => 'سخت‌گیرانه',
      };

  String get description => switch (this) {
        RadTrackingProtection.off => 'هیچ درخواست رهگیری توسط راد مسدود نمی‌شود.',
        RadTrackingProtection.standard => 'رهگیرهای شناخته‌شده و کوکی‌های شخص ثالث محدود می‌شوند.',
        RadTrackingProtection.strict => 'رهگیرها، تبلیغات رهگیر و منابع شخص ثالث بیشتری محدود می‌شوند.',
      };
}
