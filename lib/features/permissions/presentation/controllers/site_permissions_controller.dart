import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/site_permission.dart';

final sitePermissionsProvider = StateNotifierProvider<SitePermissionsController,
    Map<String, SitePermissionEntry>>((ref) {
  return SitePermissionsController()..load();
});

class SitePermissionsController
    extends StateNotifier<Map<String, SitePermissionEntry>> {
  SitePermissionsController() : super(const {});

  static const _storageKey = 'rad.sitePermissions.v1';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final entries = <String, SitePermissionEntry>{};
    for (final item in raw) {
      try {
        final json = jsonDecode(item) as Map<String, Object?>;
        final entry = SitePermissionEntry.fromJson(json);
        if (entry.host.isNotEmpty) entries[entry.key] = entry;
      } on Object {
        // Ignore a corrupted permission record only.
      }
    }
    state = entries;
    _loaded = true;
  }

  SitePermissionDecision decision(
    String host,
    SitePermissionKind kind,
  ) {
    return state['${host.toLowerCase()}:${kind.name}']?.decision ??
        SitePermissionDecision.ask;
  }

  List<SitePermissionEntry> forHost(String host) {
    final value = host.toLowerCase();
    return state.values
        .where((entry) => entry.host == value)
        .toList(growable: false);
  }

  Future<void> setDecision(
    String host,
    SitePermissionKind kind,
    SitePermissionDecision decision,
  ) async {
    await load();
    final normalizedHost = host.trim().toLowerCase();
    if (normalizedHost.isEmpty) return;
    final entry = SitePermissionEntry(
      host: normalizedHost,
      kind: kind,
      decision: decision,
    );
    final next = Map<String, SitePermissionEntry>.from(state);
    if (decision == SitePermissionDecision.ask) {
      next.remove(entry.key);
    } else {
      next[entry.key] = entry;
    }
    state = next;
    await _persist();
  }

  Future<void> clearHost(String host) async {
    await load();
    final value = host.toLowerCase();
    state = Map<String, SitePermissionEntry>.fromEntries(
      state.entries.where((item) => item.value.host != value),
    );
    await _persist();
  }

  Future<void> clearAll() async {
    state = const {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      state.values
          .map((entry) => jsonEncode(entry.toJson()))
          .toList(growable: false),
    );
  }
}
