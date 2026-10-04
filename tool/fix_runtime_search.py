from pathlib import Path

# --- Network probe: exact Google 204 + periodic polling ---
p = Path('lib/features/network/data/network_probe_service.dart')
s = p.read_text(encoding='utf-8')
s = s.replace("    final results = await Future.wait<bool>([\n      _anyReachable(internalProbes),\n      _anyReachable(globalProbes),\n    ]);\n\n    final internalReachable = results[0];\n    final globalReachable = results[1];", "    final internalFuture = _anyReachable(internalProbes);\n    final globalFuture = _google204Reachable();\n    final results = await Future.wait<bool>([internalFuture, globalFuture]);\n\n    final internalReachable = results[0];\n    final globalReachable = results[1];")
s = s.replace("  Stream<NetworkMode> watch() async* {\n    yield await check();\n    await for (final _ in _connectivity.onConnectivityChanged) {\n      yield await check();\n    }\n  }", "  Stream<NetworkMode> watch() async* {\n    var last = await check();\n    yield last;\n\n    final connectivityEvents = _connectivity.onConnectivityChanged.asBroadcastStream();\n    final periodic = Stream<void>.periodic(const Duration(seconds: 15));\n    final controller = StreamController<void>();\n    late final StreamSubscription connectivitySub;\n    late final StreamSubscription periodicSub;\n\n    connectivitySub = connectivityEvents.listen((_) => controller.add(null));\n    periodicSub = periodic.listen((_) => controller.add(null));\n\n    try {\n      await for (final _ in controller.stream) {\n        final current = await check();\n        if (current != last) {\n          last = current;\n          yield current;\n        }\n      }\n    } finally {\n      await connectivitySub.cancel();\n      await periodicSub.cancel();\n      await controller.close();\n    }\n  }")
insert = """
  Future<bool> _google204Reachable() async {
    for (final uri in globalProbes) {
      try {
        final response = await _client
            .get(uri, headers: const {
              'Cache-Control': 'no-cache',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36',
            })
            .timeout(_probeTimeout);
        if (response.statusCode == 204) return true;
      } on Object {
        // Try the next probe if one is added later.
      }
    }
    return false;
  }

"""
anchor = "  Future<bool> canReach(Uri uri) => _isReachable(uri);\n"
if insert.strip() not in s:
    s = s.replace(anchor, insert + anchor)
p.write_text(s, encoding='utf-8')

# --- Search service: robust Google + provider form submission for Iranian engines ---
p = Path('lib/features/search/data/rad_search_service.dart')
s = p.read_text(encoding='utf-8')
s = s.replace("  static const _headers = <String, String>{\n    'User-Agent':\n        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',\n    'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.7',\n  };", "  static const _headers = <String, String>{\n    'User-Agent':\n        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',\n    'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.8',\n    'Cookie': 'CONSENT=YES+cb; SOCS=CAESHAgBEhIaAB',\n    'Cache-Control': 'no-cache',\n  };")

old_google = """  Future<List<RadSearchItem>> _google(String query, int page) async {
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
"""
new_google = """  Future<List<RadSearchItem>> _google(String query, int page) async {
    final attempts = <Uri>[
      Uri.https('www.google.com', '/search', {
        'q': query,
        'hl': 'fa',
        'num': '20',
        'start': '${page * 20}',
        'filter': '0',
        'gbv': '1',
        'udm': '14',
      }),
      Uri.https('www.google.com', '/search', {
        'q': query,
        'hl': 'fa',
        'num': '20',
        'start': '${page * 20}',
        'filter': '0',
      }),
    ];

    for (final uri in attempts) {
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 400) continue;
      final doc = html_parser.parse(response.body);
      final results = _googleResults(doc, query);
      if (results.isNotEmpty) return results;
    }
    return const [];
  }

  List<RadSearchItem> _googleResults(Document doc, String query) {
    final results = <RadSearchItem>[];
    final seen = <String>{};

    final candidates = <Element>[];
    candidates.addAll(doc.querySelectorAll('div.g, div.MjjYud, div[data-snhf], div.tF2Cxc'));
    if (candidates.isEmpty) candidates.addAll(doc.querySelectorAll('h3'));

    for (final node in candidates) {
      final heading = node.localName == 'h3' ? node : node.querySelector('h3');
      final anchor = heading == null
          ? node.querySelector('a[href]')
          : (_nearestAnchor(heading) ?? node.querySelector('a[href]'));
      if (anchor == null) continue;
      final title = _clean(heading?.text ?? anchor.text);
      final url = _normalizeGoogleUrl(anchor.attributes['href'] ?? '');
      if (!_validResult(title, url, seen)) continue;
      final parsed = Uri.tryParse(url);
      if (parsed == null || parsed.host.contains('google.')) continue;
      final snippetNode = node.querySelector('.VwiC3b, .aCOpRe, [data-sncf], .IsZvec');
      final snippet = _clean(snippetNode?.text ?? _snippet(node, title));
      seen.add(url);
      results.add(RadSearchItem(title: title, url: url, snippet: snippet));
      if (results.length >= 20) break;
    }

    if (results.isEmpty) {
      for (final heading in doc.querySelectorAll('h3')) {
        final anchor = _nearestAnchor(heading);
        if (anchor == null) continue;
        final title = _clean(heading.text);
        final url = _normalizeGoogleUrl(anchor.attributes['href'] ?? '');
        if (!_validResult(title, url, seen)) continue;
        final parsed = Uri.tryParse(url);
        if (parsed == null || parsed.host.contains('google.')) continue;
        seen.add(url);
        results.add(RadSearchItem(title: title, url: url, snippet: ''));
        if (results.length >= 20) break;
      }
    }
    return results;
  }
"""
if old_google not in s:
    raise SystemExit('google block not found')
s = s.replace(old_google, new_google)

old_internal = """  Future<List<RadSearchItem>> _internalSearch(String query, int page) async {
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
"""
new_internal = """  Future<List<RadSearchItem>> _internalSearch(String query, int page) async {
    final providers = <Uri>[
      Uri.https('zarebin.ir'),
      Uri.https('gerdoo.me'),
      Uri.https('search.bertina.ir'),
      Uri.https('shaadbin.ir'),
      Uri.https('2059.ir'),
    ];

    for (final home in providers) {
      try {
        final results = await _submitProviderSearch(home, query, page)
            .timeout(const Duration(seconds: 8));
        if (results.isNotEmpty) return results;
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  Future<List<RadSearchItem>> _submitProviderSearch(
    Uri home,
    String query,
    int page,
  ) async {
    final homeResponse = await _client.get(home, headers: _headers);
    if (homeResponse.statusCode < 200 || homeResponse.statusCode >= 400) {
      return const [];
    }
    final homeDoc = html_parser.parse(homeResponse.body);
    final forms = homeDoc.querySelectorAll('form');

    for (final form in forms) {
      Element? queryInput;
      for (final input in form.querySelectorAll('input')) {
        final type = (input.attributes['type'] ?? 'text').toLowerCase();
        final name = input.attributes['name']?.trim() ?? '';
        if (name.isEmpty) continue;
        if (type == 'search' || type == 'text') {
          queryInput = input;
          break;
        }
      }
      if (queryInput == null) continue;

      final params = <String, String>{};
      for (final input in form.querySelectorAll('input')) {
        final name = input.attributes['name']?.trim() ?? '';
        if (name.isEmpty) continue;
        final type = (input.attributes['type'] ?? '').toLowerCase();
        if (type == 'hidden') params[name] = input.attributes['value'] ?? '';
      }
      params[queryInput.attributes['name']!] = query;
      if (page > 0) {
        params['page'] = '${page + 1}';
        params['p'] = '${page + 1}';
        params['start'] = '${page * 10}';
      }

      final actionRaw = form.attributes['action']?.trim() ?? '';
      final action = actionRaw.isEmpty ? home : home.resolve(actionRaw);
      final method = (form.attributes['method'] ?? 'get').toLowerCase();
      http.Response response;
      if (method == 'post') {
        response = await _client.post(action, headers: _headers, body: params);
      } else {
        response = await _client.get(
          action.replace(queryParameters: {...action.queryParameters, ...params}),
          headers: _headers,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 400) continue;
      final doc = html_parser.parse(response.body);
      final results = _genericResults(doc, providerHost: home.host);
      if (results.isNotEmpty) return results;
    }

    // Compatibility fallback for providers that render the form client-side.
    for (final key in const ['q', 'query', 'search', 'keyword', 'term']) {
      final params = <String, String>{key: query};
      if (page > 0) params['page'] = '${page + 1}';
      final response = await _client.get(
        home.replace(queryParameters: params),
        headers: _headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 400) continue;
      final results = _genericResults(
        html_parser.parse(response.body),
        providerHost: home.host,
      );
      if (results.isNotEmpty) return results;
    }
    return const [];
  }
"""
if old_internal not in s:
    raise SystemExit('internal block not found')
s = s.replace(old_internal, new_internal)

s = s.replace("  List<RadSearchItem> _genericResults(Document doc) {", "  List<RadSearchItem> _genericResults(Document doc, {String? providerHost}) {")
s = s.replace("      final url = anchor.attributes['href']?.trim() ?? '';\n      if (!_validResult(title, url, seen)) continue;\n      final parsed = Uri.tryParse(url);\n      if (parsed == null || parsed.host.contains('zarebin.ir')) continue;", "      var url = anchor.attributes['href']?.trim() ?? '';\n      if (url.startsWith('//')) url = 'https:$url';\n      if (url.startsWith('/') && providerHost != null) {\n        url = Uri.https(providerHost, url).toString();\n      }\n      if (!_validResult(title, url, seen)) continue;\n      final parsed = Uri.tryParse(url);\n      if (parsed == null) continue;\n      if (providerHost != null && parsed.host == providerHost) continue;")

# Version bump
p.write_text(s, encoding='utf-8')

p = Path('pubspec.yaml')
s = p.read_text(encoding='utf-8').replace('version: 1.2.0+5', 'version: 1.2.1+6', 1)
p.write_text(s, encoding='utf-8')

p = Path('CHANGELOG.md')
s = p.read_text(encoding='utf-8')
entry = """## 1.2.1 — Runtime Search Reliability\n\n- اصلاح تشخیص اینترنت بین‌الملل با پاسخ دقیق Google 204\n- بررسی دوره‌ای وضعیت شبکه بدون نیاز به تغییر Wi‑Fi/دیتا\n- parser مقاوم‌تر نتایج Google با حالت HTML سبک و consent cookie\n- شناسایی و submit خودکار فرم واقعی موتورهای جستجوی داخلی\n- fallback بین چند موتور جستجوی داخلی بدون نمایش نام منبع\n- رفع مشکل نسخه‌ای که Build موفق داشت اما در زمان اجرا نتیجه جستجو نمی‌داد\n\n"""
if '## 1.2.1 — Runtime Search Reliability' not in s:
    s = s.replace('# Changelog\n\n', '# Changelog\n\n' + entry, 1)
p.write_text(s, encoding='utf-8')

print('runtime search reliability patch applied')
