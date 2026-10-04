import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/bookmark_entry.dart';

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, List<BookmarkEntry>>((ref) {
  return BookmarksController()..load();
});

class BookmarksController extends StateNotifier<List<BookmarkEntry>> {
  BookmarksController() : super(const []);

  static const _storageKey = 'rad.bookmarks.v1';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final entries = <BookmarkEntry>[];
    for (final item in raw) {
      try {
        final json = jsonDecode(item) as Map<String, Object?>;
        entries.add(BookmarkEntry.fromJson(json));
      } on Object {
        // Ignore only the corrupted record.
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = entries;
    _loaded = true;
  }

  bool contains(Uri url) => state.any((item) => item.url == url);

  Future<void> toggle({required Uri url, required String title}) async {
    await load();
    if (contains(url)) {
      state = state.where((item) => item.url != url).toList(growable: false);
    } else {
      final normalizedTitle = title.trim().isEmpty ? url.host : title.trim();
      state = [
        BookmarkEntry(
          url: url,
          title: normalizedTitle,
          createdAt: DateTime.now(),
        ),
        ...state,
      ];
    }
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
