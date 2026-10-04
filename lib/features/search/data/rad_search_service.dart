import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../settings/domain/app_settings.dart';

class RadSearchItem {
  const RadSearchItem({
    required this.title,
    required this.url,
    required this.snippet,
  });

  final String title;
  final String url;
  final String snippet;

  String get host => Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;

  String get faviconUrl {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return '';
    return Uri.https('www.google.com', '/s2/favicons', {
      'domain': uri.host,
      'sz': '64',
    }).toString();
  }
}

class RadMediaItem {
  const RadMediaItem({
    required this.title,
    required this.sourceUrl,
    required this.thumbnailUrl,
    this.mediaUrl,
  });

  final String title;
  final String sourceUrl;
  final String thumbnailUrl;
  final String? mediaUrl;

  String get host =>
      Uri.tryParse(sourceUrl)?.host.replaceFirst('www.', '') ?? sourceUrl;
}

class RadSearchResponse {
  const RadSearchResponse({
    required this.results,
    required this.requestedEngine,
    required this.usedEngine,
  });

  final List<RadSearchItem> results;
  final RadSearchEngine requestedEngine;
  final RadSearchEngine usedEngine;

  bool get usedFallback => requestedEngine != usedEngine;
}

class RadSearchService {
  RadSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.7',
  };

  Future<RadSearchResponse> search({
    required String query,
    required RadSearchEngine engine,
    int page = 0,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      return RadSearchResponse(
        results: const [],
        requestedEngine: engine,
        usedEngine: engine,
      );
    }

    final order = switch (engine) {
      RadSearchEngine.google => const [
          RadSearchEngine.google,
        ],
      RadSearchEngine.zarebin => const [
          RadSearchEngine.zarebin,
        ],
      RadSearchEngine.bing => const [
          RadSearchEngine.bing,
          RadSearchEngine.duckDuckGo,
          RadSearchEngine.google,
        ],
      RadSearchEngine.duckDuckGo => const [
          RadSearchEngine.duckDuckGo,
          RadSearchEngine.google,
          RadSearchEngine.bing,
        ],
    };

    Object? lastError;
    for (final candidate in order) {
      try {
        final results = await _searchWith(candidate, clean, page)
            .timeout(const Duration(seconds: 12));
        if (results.isNotEmpty) {
          return RadSearchResponse(
            results: results,
            requestedEngine: engine,
            usedEngine: candidate,
          );
        }
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) throw lastError;
    return RadSearchResponse(
      results: const [],
      requestedEngine: engine,
      usedEngine: engine,
    );
  }

  Future<List<RadMediaItem>> searchImages(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];
    try {
      return await _bingImages(clean).timeout(const Duration(seconds: 12));
    } catch (_) {
      return const [];
    }
  }

  Future<List<RadMediaItem>> searchVideos(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];
    try {
      final direct = await _bingVideos(clean).timeout(const Duration(seconds: 12));
      if (direct.isNotEmpty) return direct;
    } catch (_) {}

    try {
      final web = await _bing('$clean ویدیو').timeout(const Duration(seconds: 10));
      return web
          .where((item) => _looksLikeVideoHost(item.host))
          .map(
            (item) => RadMediaItem(
              title: item.title,
              sourceUrl: item.url,
              thumbnailUrl: '',
            ),
          )
          .take(12)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<RadSearchItem>> _searchWith(
    RadSearchEngine engine,
    String query,
    int page,
  ) async {
    return switch (engine) {
      RadSearchEngine.google => _google(query, page),
      RadSearchEngine.zarebin => _internalSearch(query, page),
      RadSearchEngine.bing => _bing(query),
      RadSearchEngine.duckDuckGo => _duckDuckGo(query),
    };
  }

  Future<List<RadSearchItem>> _google(String query, int page) async {
    final uri = Uri.https('www.google.com', '/search', {
      'q': query,
      'hl': 'fa',
      'num': '20',
      'start': '${page * 20}',
      'filter': '0',
    });
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 400) return const [];
    final doc = html_parser.parse(response.body);
    final results = <RadSearchItem>[];
    final seen = <String>{};

    for (final heading in doc.querySelectorAll('h3')) {
      final anchor = _nearestAnchor(heading);
      if (anchor == null) continue;
      final title = _clean(heading.text);
      final url = _normalizeGoogleUrl(anchor.attributes['href'] ?? '');
      if (!_validResult(title, url, seen)) continue;
      final container = heading.parent?.parent?.parent ?? heading.parent;
      final snippet = _snippet(container, title);
      seen.add(url);
      results.add(RadSearchItem(title: title, url: url, snippet: snippet));
      if (results.length >= 20) break;
    }
    return results;
  }

  Future<List<RadSearchItem>> _bing(String query) async {
    final uri = Uri.https('www.bing.com', '/search', {
      'q': query,
      'setlang': 'fa',
      'count': '30',
    });
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 400) return const [];
    final doc = html_parser.parse(response.body);
    final results = <RadSearchItem>[];
    final seen = <String>{};

    for (final node in doc.querySelectorAll('li.b_algo')) {
      final anchor = node.querySelector('h2 a, a');
      if (anchor == null) continue;
      final title = _clean(anchor.text);
      final url = anchor.attributes['href']?.trim() ?? '';
      if (!_validResult(title, url, seen)) continue;
      final snippet = _clean(node.querySelector('.b_caption p, p')?.text ?? '');
      seen.add(url);
      results.add(RadSearchItem(title: title, url: url, snippet: snippet));
      if (results.length >= 30) break;
    }
    return results;
  }

  Future<List<RadSearchItem>> _duckDuckGo(String query) async {
    final uri = Uri.https('html.duckduckgo.com', '/html/', {'q': query});
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 400) return const [];
    final doc = html_parser.parse(response.body);
    final results = <RadSearchItem>[];
    final seen = <String>{};

    for (final node in doc.querySelectorAll('.result')) {
      final anchor = node.querySelector('a.result__a');
      if (anchor == null) continue;
      final title = _clean(anchor.text);
      final url = _normalizeDuckUrl(anchor.attributes['href'] ?? '');
      if (!_validResult(title, url, seen)) continue;
      final snippet = _clean(node.querySelector('.result__snippet')?.text ?? '');
      seen.add(url);
      results.add(RadSearchItem(title: title, url: url, snippet: snippet));
      if (results.length >= 30) break;
    }
    return results;
  }

  Future<List<RadMediaItem>> _bingImages(String query) async {
    final uri = Uri.https('www.bing.com', '/images/search', {
      'q': query,
      'form': 'HDRSC3',
      'first': '1',
    });
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 400) return const [];
    final doc = html_parser.parse(response.body);
    final results = <RadMediaItem>[];
    final seen = <String>{};

    for (final anchor in doc.querySelectorAll('a.iusc')) {
      final raw = anchor.attributes['m'];
      if (raw == null || raw.isEmpty) continue;
      try {
        final meta = jsonDecode(raw) as Map<String, dynamic>;
        final image = meta['murl']?.toString().trim() ?? '';
        final source = meta['purl']?.toString().trim() ?? '';
        final title = _clean(meta['t']?.toString() ?? anchor.attributes['aria-label'] ?? '');
        if (image.isEmpty || source.isEmpty || seen.contains(image)) continue;
        if (Uri.tryParse(image)?.hasScheme != true || Uri.tryParse(source)?.hasScheme != true) {
          continue;
        }
        seen.add(image);
        results.add(
          RadMediaItem(
            title: title.isEmpty ? query : title,
            sourceUrl: source,
            thumbnailUrl: image,
            mediaUrl: image,
          ),
        );
        if (results.length >= 36) break;
      } catch (_) {
        continue;
      }
    }
    return results;
  }

  Future<List<RadMediaItem>> _bingVideos(String query) async {
    final uri = Uri.https('www.bing.com', '/videos/search', {
      'q': query,
      'FORM': 'HDRSC4',
    });
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 400) return const [];
    final doc = html_parser.parse(response.body);
    final results = <RadMediaItem>[];
    final seen = <String>{};

    for (final node in doc.querySelectorAll('.mc_vtvc, .mc_vtvc_con_rc, .dg_u')) {
      final anchor = node.querySelector('a[href]');
      if (anchor == null) continue;
      final url = anchor.attributes['href']?.trim() ?? '';
      final parsed = Uri.tryParse(url);
      if (parsed == null || !parsed.hasScheme || seen.contains(url)) continue;
      if (parsed.host.contains('bing.com')) continue;
      final image = node.querySelector('img');
      final thumb = image?.attributes['data-src'] ??
          image?.attributes['src'] ??
          image?.attributes['data-original'] ??
          '';
      var title = _clean(
        anchor.attributes['aria-label'] ??
            anchor.attributes['title'] ??
            node.querySelector('.mc_vtvc_title, .b_promtxt')?.text ??
            anchor.text,
      );
      if (title.isEmpty) title = parsed.host.replaceFirst('www.', '');
      seen.add(url);
      results.add(
        RadMediaItem(
          title: title,
          sourceUrl: url,
          thumbnailUrl: thumb,
        ),
      );
      if (results.length >= 24) break;
    }
    return results;
  }

  Future<List<RadSearchItem>> _internalSearch(String query, int page) async {
    for (final key in const ['q', 'query', 'search']) {
      final params = <String, String>{key: query};
      if (page > 0) params['page'] = '${page + 1}';
      final uri = Uri.https('zarebin.ir', '/', params);
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 400) continue;
      final doc = html_parser.parse(response.body);
      final results = _genericResults(doc);
      if (results.isNotEmpty) return results;
    }
    return const [];
  }

  List<RadSearchItem> _genericResults(Document doc) {
    final results = <RadSearchItem>[];
    final seen = <String>{};
    for (final anchor in doc.querySelectorAll('a[href]')) {
      final heading = anchor.querySelector('h1,h2,h3,h4');
      final title = _clean(heading?.text ?? anchor.text);
      final url = anchor.attributes['href']?.trim() ?? '';
      if (!_validResult(title, url, seen)) continue;
      final parsed = Uri.tryParse(url);
      if (parsed == null || parsed.host.contains('zarebin.ir')) continue;
      final snippet = _snippet(anchor.parent, title);
      seen.add(url);
      results.add(RadSearchItem(title: title, url: url, snippet: snippet));
      if (results.length >= 30) break;
    }
    return results;
  }

  Element? _nearestAnchor(Element element) {
    Element? current = element.parent;
    while (current != null) {
      if (current.localName == 'a' && current.attributes['href'] != null) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  bool _validResult(String title, String url, Set<String> seen) {
    if (title.length < 2 || url.isEmpty || seen.contains(url)) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    return true;
  }

  bool _looksLikeVideoHost(String host) {
    final value = host.toLowerCase();
    return value.contains('youtube.com') ||
        value.contains('youtu.be') ||
        value.contains('aparat.com') ||
        value.contains('namasha.com') ||
        value.contains('filmnet.ir') ||
        value.contains('filimo.com') ||
        value.contains('namava.ir') ||
        value.contains('vimeo.com');
  }

  String _normalizeGoogleUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;
    if ((uri.host.isEmpty || uri.host.contains('google.')) && uri.path == '/url') {
      return uri.queryParameters['q'] ?? uri.queryParameters['url'] ?? raw;
    }
    return raw;
  }

  String _normalizeDuckUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;
    return uri.queryParameters['uddg'] ?? raw;
  }

  String _snippet(Element? container, String title) {
    if (container == null) return '';
    var text = _clean(container.text);
    if (text.startsWith(title)) text = text.substring(title.length).trim();
    if (text.length > 320) text = '${text.substring(0, 320)}…';
    return text;
  }

  String _clean(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
