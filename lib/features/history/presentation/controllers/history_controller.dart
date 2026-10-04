import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/history_entry.dart';

final historyProvider =
    StateNotifierProvider<HistoryController, List<HistoryEntry>>((ref) {
  return HistoryController()..load();
});

class HistoryController extends StateNotifier<List<HistoryEntry>> {
  HistoryController() : super(const []);

  static const _storageKey = 'rad.history.v1';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final entries = <HistoryEntry>[];
    for (final item in raw) {
      try {
        final json = jsonDecode(item) as Map<String, Object?>;
        entries.add(HistoryEntry.fromJson(json));
      } on Object {
        // Ignore corrupted individual records without losing the whole history.
      }
    }
    entries.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    state = entries;
    _loaded = true;
  }

  Future<void> record({required Uri url, required String title}) async {
    if (url.scheme != 'http' && url.scheme != 'https') return;
    await load();
    final normalizedTitle = title.trim().isEmpty ? url.host : title.trim();
    final withoutSameUrl = state.where((item) => item.url != url).toList();
    state = [
      HistoryEntry(
        url: url,
        title: normalizedTitle,
        visitedAt: DateTime.now(),
      ),
      ...withoutSameUrl,
    ].take(500).toList(growable: false);
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
