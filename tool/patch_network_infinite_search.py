from pathlib import Path

# Network probe: Google is the authoritative international probe.
p = Path('lib/features/network/data/network_probe_service.dart')
s = p.read_text(encoding='utf-8')
s = s.replace("        globalProbes = globalProbes ??\n            [\n              Uri.https('www.google.com', '/generate_204'),\n              Uri.https('www.cloudflare.com', '/cdn-cgi/trace'),\n              Uri.https('www.bing.com'),\n            ];", "        globalProbes = globalProbes ??\n            [\n              Uri.https('www.google.com', '/generate_204'),\n            ];")
p.write_text(s, encoding='utf-8')

# Home status labels.
p = Path('lib/features/home/presentation/pages/home_page.dart')
s = p.read_text(encoding='utf-8')
s = s.replace("NetworkMode.fullInternet => ('آنلاین', Icons.circle),", "NetworkMode.fullInternet => ('اینترنت بین‌الملل', Icons.public_rounded),")
s = s.replace("NetworkMode.internalOnly => ('شبکه داخلی', Icons.public_rounded),", "NetworkMode.internalOnly => ('اینترنت داخلی', Icons.hub_rounded),")
s = s.replace("null => ('بررسی شبکه', Icons.more_horiz_rounded),", "null => ('در حال بررسی اینترنت', Icons.more_horiz_rounded),")
p.write_text(s, encoding='utf-8')

# Search service: add real paging for Google and internal search.
p = Path('lib/features/search/data/rad_search_service.dart')
s = p.read_text(encoding='utf-8')
s = s.replace("  Future<RadSearchResponse> search({\n    required String query,\n    required RadSearchEngine engine,\n  }) async {", "  Future<RadSearchResponse> search({\n    required String query,\n    required RadSearchEngine engine,\n    int page = 0,\n  }) async {")
s = s.replace("        final results = await _searchWith(candidate, clean)\n            .timeout(const Duration(seconds: 12));", "        final results = await _searchWith(candidate, clean, page)\n            .timeout(const Duration(seconds: 12));")
s = s.replace("  Future<List<RadSearchItem>> _searchWith(\n    RadSearchEngine engine,\n    String query,\n  ) async {", "  Future<List<RadSearchItem>> _searchWith(\n    RadSearchEngine engine,\n    String query,\n    int page,\n  ) async {")
s = s.replace("      RadSearchEngine.google => _google(query),\n      RadSearchEngine.zarebin => _zarebin(query),", "      RadSearchEngine.google => _google(query, page),\n      RadSearchEngine.zarebin => _internalSearch(query, page),")
s = s.replace("  Future<List<RadSearchItem>> _google(String query) async {", "  Future<List<RadSearchItem>> _google(String query, int page) async {")
s = s.replace("      'num': '50',\n      'filter': '0',", "      'num': '20',\n      'start': '${page * 20}',\n      'filter': '0',")
s = s.replace("      if (results.length >= 50) break;", "      if (results.length >= 20) break;", 1)

# Rename Zarebin routine and support page parameters; keep provider details internal.
s = s.replace("  Future<List<RadSearchItem>> _zarebin(String query) async {\n    for (final key in const ['q', 'query', 'search']) {\n      final uri = Uri.https('zarebin.ir', '/', {key: query});", "  Future<List<RadSearchItem>> _internalSearch(String query, int page) async {\n    for (final key in const ['q', 'query', 'search']) {\n      final params = <String, String>{key: query};\n      if (page > 0) params['page'] = '${page + 1}';\n      final uri = Uri.https('zarebin.ir', '/', params);")
p.write_text(s, encoding='utf-8')

# Results page: infinite loading and no provider disclosure.
p = Path('lib/features/search/presentation/pages/search_results_page.dart')
s = p.read_text(encoding='utf-8')
s = s.replace("  int _visibleResults = 15;", "  int _visibleResults = 20;\n  int _page = 0;\n  bool _loadingMore = false;\n  bool _hasMore = true;")
old = """  void _onScroll() {\n    if (!_scrollController.hasClients || _section != _SearchSection.all) return;\n    if (_scrollController.position.extentAfter > 420) return;\n    if (_visibleResults >= _results.length) return;\n    setState(() => _visibleResults = (_visibleResults + 10).clamp(0, _results.length));\n  }\n"""
new = """  void _onScroll() {\n    if (!_scrollController.hasClients || _section != _SearchSection.all) return;\n    if (_scrollController.position.extentAfter > 520) return;\n    if (_visibleResults < _results.length) {\n      setState(() => _visibleResults = (_visibleResults + 10).clamp(0, _results.length));\n      return;\n    }\n    if (_hasMore && !_loadingMore) _loadMore();\n  }\n\n  Future<void> _loadMore() async {\n    if (_loadingMore || !_hasMore || _query.isEmpty) return;\n    final generation = _generation;\n    setState(() => _loadingMore = true);\n    try {\n      final nextPage = _page + 1;\n      final response = await _service.search(\n        query: _query,\n        engine: widget.engine,\n        page: nextPage,\n      );\n      if (!mounted || generation != _generation) return;\n      final existing = _results.map((e) => e.url).toSet();\n      final incoming = response.results.where((e) => !existing.contains(e.url)).toList();\n      setState(() {\n        _page = nextPage;\n        _results = [..._results, ...incoming];\n        _visibleResults = _results.length;\n        _hasMore = incoming.isNotEmpty;\n        _loadingMore = false;\n      });\n    } catch (_) {\n      if (mounted && generation == _generation) {\n        setState(() => _loadingMore = false);\n      }\n    }\n  }\n"""
if old not in s:
    raise SystemExit('scroll block not found')
s = s.replace(old, new)
s = s.replace("      _visibleResults = 15;", "      _visibleResults = 20;\n      _page = 0;\n      _hasMore = true;\n      _loadingMore = false;")
s = s.replace("      final response = await _service.search(query: value, engine: widget.engine);", "      final response = await _service.search(query: value, engine: widget.engine, page: 0);")
# Remove fallback/provider disclosure block entirely.
start = s.find("              if (usedFallback)\n")
if start != -1:
    end_marker = "              Expanded(\n"
    end = s.find(end_marker, start)
    if end != -1:
        s = s[:start] + s[end:]
# Remove unused local variables if present.
s = s.replace("    final usedEngine = _usedEngine;\n    final usedFallback = usedEngine != null && usedEngine != widget.engine;\n", "")
# Replace end-of-list hint with loading-more indicator.
old_hint = """        if (_visibleResults < _results.length) ...[\n          const SizedBox(height: 10),\n          Center(\n            child: Text(\n              'برای نتایج بیشتر به پایین بروید',\n              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),\n            ),\n          ),\n        ],\n"""
new_hint = """        if (_loadingMore) ...[\n          const SizedBox(height: 18),\n          const Center(child: CircularProgressIndicator(strokeWidth: 2)),\n          const SizedBox(height: 18),\n        ],\n"""
s = s.replace(old_hint, new_hint)
p.write_text(s, encoding='utf-8')

# Version bump + changelog.
p = Path('pubspec.yaml')
s = p.read_text(encoding='utf-8').replace('version: 1.1.1+4', 'version: 1.2.0+5', 1)
p.write_text(s, encoding='utf-8')

p = Path('CHANGELOG.md')
s = p.read_text(encoding='utf-8')
entry = """## 1.2.0 — Network-aware Infinite Search\n\n- نمایش وضعیت اینترنت بین‌الملل / اینترنت داخلی در بالای Home\n- تشخیص اینترنت بین‌الملل با دسترسی واقعی به Google\n- جستجوی Google در حالت بین‌الملل بدون نمایش نام موتور در نتایج\n- جستجوی داخلی در حالت شبکه داخلی بدون نمایش منبع جستجو\n- بارگذاری صفحه‌به‌صفحه و ادامه نتایج هنگام اسکرول\n- یکسان‌سازی رفتار جستجو با وضعیت واقعی شبکه\n\n"""
if '## 1.2.0 — Network-aware Infinite Search' not in s:
    s = s.replace('# Changelog\n\n', '# Changelog\n\n' + entry, 1)
p.write_text(s, encoding='utf-8')
print('network-aware infinite search patch applied')
