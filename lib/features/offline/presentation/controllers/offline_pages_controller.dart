import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/offline_page.dart';

final offlinePagesProvider =
    StateNotifierProvider<OfflinePagesController, List<OfflinePage>>((ref) {
  return OfflinePagesController()..load();
});

class OfflinePagesController extends StateNotifier<List<OfflinePage>> {
  OfflinePagesController() : super(const []);

  static const _storageKey = 'rad.offline_pages.v1';
  static const _maxContentLength = 160000;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final entries = <OfflinePage>[];
    for (final item in raw) {
      try {
        entries.add(
          OfflinePage.fromJson(jsonDecode(item) as Map<String, Object?>),
        );
      } on Object {
        // Ignore only the corrupted snapshot.
      }
    }
    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    state = entries;
    _loaded = true;
  }

  bool contains(Uri url) => state.any((item) => item.url == url);

  Future<void> save({
    required Uri url,
    required String title,
    required String content,
  }) async {
    await load();
    final normalized = content.trim();
    if (normalized.isEmpty) return;
    final clipped = normalized.length > _maxContentLength
        ? normalized.substring(0, _maxContentLength)
        : normalized;
    final entry = OfflinePage(
      url: url,
      title: title.trim().isEmpty ? url.host : title.trim(),
      content: clipped,
      savedAt: DateTime.now(),
    );
    state = [
      entry,
      ...state.where((item) => item.url != url),
    ];
    await _persist();
  }

  Future<void> remove(Uri url) async {
    await load();
    state = state.where((item) => item.url != url).toList(growable: false);
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      state.map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }
}
