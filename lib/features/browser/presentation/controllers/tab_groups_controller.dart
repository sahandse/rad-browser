import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/tab_group.dart';

final tabGroupsProvider =
    StateNotifierProvider<TabGroupsController, List<TabGroup>>((ref) {
  return TabGroupsController()..load();
});

class TabGroupsController extends StateNotifier<List<TabGroup>> {
  TabGroupsController() : super(const []);

  static const _storageKey = 'rad.tabGroups.v1';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final groups = <TabGroup>[];
    for (final item in raw) {
      try {
        final json = jsonDecode(item) as Map<String, Object?>;
        groups.add(TabGroup.fromJson(json));
      } on Object {
        // Ignore only the corrupted group record.
      }
    }
    groups.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = groups;
    _loaded = true;
  }

  Future<TabGroup?> create(String title) async {
    await load();
    final value = title.trim();
    if (value.isEmpty) return null;
    final group = TabGroup(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: value,
      createdAt: DateTime.now(),
    );
    state = [...state, group];
    await _persist();
    return group;
  }

  Future<void> rename(String id, String title) async {
    final value = title.trim();
    if (value.isEmpty) return;
    state = [
      for (final group in state)
        if (group.id == id) group.copyWith(title: value) else group,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((group) => group.id != id).toList(growable: false);
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
      state.map((group) => jsonEncode(group.toJson())).toList(growable: false),
    );
  }
}
