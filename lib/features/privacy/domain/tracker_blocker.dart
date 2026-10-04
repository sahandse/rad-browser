import '../../settings/domain/app_settings.dart';

class TrackerBlocker {
  TrackerBlocker(this.mode);

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
