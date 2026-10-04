import 'package:flutter/material.dart';

enum RadThemePreference { system, light, dark }
enum RadSearchEngine { google, bing, duckDuckGo }
enum RadUiDensity { comfortable, compact }

class AppSettings {
  const AppSettings({
    this.theme = RadThemePreference.system,
    this.searchEngine = RadSearchEngine.google,
    this.uiDensity = RadUiDensity.comfortable,
  });

  final RadThemePreference theme;
  final RadSearchEngine searchEngine;
  final RadUiDensity uiDensity;

  ThemeMode get themeMode => switch (theme) {
        RadThemePreference.system => ThemeMode.system,
        RadThemePreference.light => ThemeMode.light,
        RadThemePreference.dark => ThemeMode.dark,
      };

  AppSettings copyWith({
    RadThemePreference? theme,
    RadSearchEngine? searchEngine,
    RadUiDensity? uiDensity,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      searchEngine: searchEngine ?? this.searchEngine,
      uiDensity: uiDensity ?? this.uiDensity,
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
