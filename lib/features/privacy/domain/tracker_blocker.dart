import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/domain/app_settings.dart';

class TrackingExceptionRegistry {
  static const storageKey = 'rad.trackingExceptions.v1';
  static final Set<String> _hosts = <String>{};
  static bool _loaded = false;

  static Set<String> get hosts => Set.unmodifiable(_hosts);

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _hosts
      ..clear()
      ..addAll(
        (prefs.getStringList(storageKey) ?? const <String>[])
            .map(_normalize)
            .where((host) => host.isNotEmpty),
      );
    _loaded = true;
  }

  static bool contains(String host) {
    final value = _normalize(host);
    if (value.isEmpty) return false;
    return _hosts.any(
      (exception) =>
          value == exception || value.endsWith('.$exception'),
    );
  }

  static Future<void> add(String host) async {
    await ensureLoaded();
    final value = _normalize(host);
    if (value.isEmpty) return;
    _hosts.add(value);
    await _persist();
  }

  static Future<void> remove(String host) async {
    await ensureLoaded();
    _hosts.remove(_normalize(host));
    await _persist();
  }

  static Future<void> clear() async {
    await ensureLoaded();
    _hosts.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = _hosts.toList()..sort();
    await prefs.setStringList(storageKey, sorted);
  }

  static String _normalize(String value) {
    var host = value.trim().toLowerCase();
    final uri = Uri.tryParse(
      host.contains('://') ? host : 'https://$host',
    );
    if (uri != null && uri.host.isNotEmpty) host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    return host.replaceAll(RegExp(r'^\.+|\.+$'), '');
  }
}

class TrackerBlocker {
  TrackerBlocker(this.mode) {
    unawaited(TrackingExceptionRegistry.ensureLoaded());
  }

  final RadTrackingProtection mode;

  static const _standardHosts = <String>{
    'doubleclick.net',
    'google-analytics.com',
    'googletagmanager.com',
    'googlesyndication.com',
    'facebook.net',
    'connect.facebook.net',
    'scorecardresearch.com',
    'hotjar.com',
    'clarity.ms',
    'segment.io',
    'segment.com',
    'mixpanel.com',
    'amplitude.com',
  };

  static const _strictExtraHosts = <String>{
    'adservice.google.com',
    'adsrvr.org',
    'criteo.com',
    'criteo.net',
    'taboola.com',
    'outbrain.com',
    'quantserve.com',
    'demdex.net',
    'branch.io',
  };

  bool shouldBlock(Uri request, Uri? topLevel) {
    if (mode == RadTrackingProtection.off) return false;
    final requestHost = _normalizedHost(request.host);
    if (requestHost.isEmpty) return false;

    final topHost = topLevel == null ? '' : _normalizedHost(topLevel.host);
    if (topHost.isNotEmpty && TrackingExceptionRegistry.contains(topHost)) {
      return false;
    }

    final thirdParty = topHost.isNotEmpty && !_sameSite(requestHost, topHost);
    if (!thirdParty) return false;

    if (_matchesAny(requestHost, _standardHosts)) return true;
    if (mode == RadTrackingProtection.strict &&
        _matchesAny(requestHost, _strictExtraHosts)) {
      return true;
    }
    return false;
  }

  bool _matchesAny(String host, Set<String> patterns) {
    for (final pattern in patterns) {
      if (host == pattern || host.endsWith('.$pattern')) return true;
    }
    return false;
  }

  bool _sameSite(String a, String b) {
    if (a == b) return true;
    return a.endsWith('.$b') || b.endsWith('.$a');
  }

  String _normalizedHost(String value) {
    final host = value.trim().toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}
