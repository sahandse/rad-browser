import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/browser_tab.dart';

final browserTabsProvider =
    StateNotifierProvider<BrowserTabsController, List<BrowserTab>>((ref) {
  return BrowserTabsController()..load();
});

class BrowserTabsController extends StateNotifier<List<BrowserTab>> {
  BrowserTabsController() : super(const []);

  static const _storageKey = 'rad.tabs.v1';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final restored = <BrowserTab>[];
    for (final item in raw) {
      try {
        final json = jsonDecode(item) as Map<String, Object?>;
        restored.add(BrowserTab.fromJson(json));
      } on Object {
        // Ignore only corrupted tab state.
      }
    }
    if (state.isEmpty) state = restored;
    _loaded = true;
  }

  String open(Uri url) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final tab = BrowserTab(
      id: id,
      url: url,
      title: url.host.isEmpty ? 'تب جدید' : url.host,
      isLoading: true,
    );
    state = [...state, tab];
    unawaited(_persist());
    return id;
  }

  void update(
    String id, {
    Uri? url,
    String? title,
    Uri? faviconUrl,
    bool? isLoading,
    double? progress,
  }) {
    state = [
      for (final tab in state)
        if (tab.id == id)
          tab.copyWith(
            url: url,
            title: title,
            faviconUrl: faviconUrl,
            isLoading: isLoading,
            progress: progress,
          )
        else
          tab,
    ];
    unawaited(_persist());
  }

  void close(String id) {
    state = state.where((tab) => tab.id != id).toList(growable: false);
    unawaited(_persist());
  }

  void closeAll() {
    state = const [];
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      state.map((tab) => jsonEncode(tab.toJson())).toList(growable: false),
    );
  }
}
