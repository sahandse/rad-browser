import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../browser/presentation/pages/browser_page.dart';
import '../../../settings/domain/app_settings.dart';

class RadSearchResultsPage extends StatefulWidget {
  const RadSearchResultsPage({
    super.key,
    required this.query,
    required this.engine,
  });

  final String query;
  final RadSearchEngine engine;

  @override
  State<RadSearchResultsPage> createState() => _RadSearchResultsPageState();
}

class _RadSearchResultsPageState extends State<RadSearchResultsPage> {
  late final TextEditingController _searchController;
  late String _query;
  InAppWebViewController? _controller;
  List<_RadSearchResult> _results = const [];
  bool _loading = true;
  bool _zarebinSubmitted = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _query = widget.query.trim();
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Uri _providerUri() {
    return switch (widget.engine) {
      RadSearchEngine.google =>
        Uri.https('www.google.com', '/search', {'q': _query, 'hl': 'fa'}),
      RadSearchEngine.zarebin => Uri.https('zarebin.ir', '/'),
      RadSearchEngine.bing =>
        Uri.https('www.bing.com', '/search', {'q': _query}),
      RadSearchEngine.duckDuckGo =>
        Uri.https('duckduckgo.com', '/', {'q': _query}),
    };
  }

  Future<void> _reloadSearch(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;
    setState(() {
      _query = value;
      _loading = true;
      _error = null;
      _results = const [];
      _zarebinSubmitted = false;
      _generation++;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_providerUri().toString())),
    );
  }

  Future<void> _onProviderLoaded(InAppWebViewController controller) async {
    if (!mounted || _query.isEmpty) return;
    if (widget.engine == RadSearchEngine.zarebin && !_zarebinSubmitted) {
      _zarebinSubmitted = true;
      final encoded = jsonEncode(_query);
      await controller.evaluateJavascript(source: '''
        (() => {
          const input = document.querySelector(
            'input[placeholder*="جستجو"], input[type="search"], input[name="q"], input[name="query"], input[type="text"]'
          );
          if (!input) return false;
          const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
          if (setter) setter.call(input, $encoded); else input.value = $encoded;
          input.dispatchEvent(new Event('input', {bubbles: true}));
          input.dispatchEvent(new Event('change', {bubbles: true}));
          const form = input.closest('form');
          if (form) {
            if (typeof form.requestSubmit === 'function') form.requestSubmit();
            else form.submit();
            return true;
          }
          input.dispatchEvent(new KeyboardEvent('keydown', {
            key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true
          }));
          input.dispatchEvent(new KeyboardEvent('keyup', {
            key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true
          }));
          return true;
        })();
      ''');
      final generation = _generation;
      Future<void>.delayed(const Duration(milliseconds: 1600), () {
        if (mounted && generation == _generation) _extractResults(controller);
      });
      Future<void>.delayed(const Duration(milliseconds: 3600), () {
        if (mounted && generation == _generation && _results.isEmpty) {
          _extractResults(controller);
        }
      });
      return;
    }
    await _extractResults(controller);
  }

  Future<void> _extractResults(InAppWebViewController controller) async {
    final raw = await controller.evaluateJavascript(source: r'''
      (() => {
        const clean = (value) => (value || '').replace(/\s+/g, ' ').trim();
        const isSearchHost = (host) =>
          host.includes('google.') || host.includes('bing.') ||
          host.includes('duckduckgo.') || host.includes('zarebin.');
        const out = [];
        const seen = new Set();
        const anchors = Array.from(document.querySelectorAll('a[href]'));
        for (const anchor of anchors) {
          const heading = anchor.querySelector('h1,h2,h3,h4');
          const title = clean(heading?.innerText || anchor.innerText);
          if (!title || title.length < 3 || title.length > 180) continue;
          let url;
          try { url = new URL(anchor.href, location.href); } catch (_) { continue; }
          if (!['http:', 'https:'].includes(url.protocol)) continue;
          if (url.hostname.includes('google.') && url.pathname === '/url') {
            const target = url.searchParams.get('q') || url.searchParams.get('url');
            if (target) {
              try { url = new URL(target); } catch (_) {}
            }
          }
          const href = url.toString();
          if (seen.has(href)) continue;
          if (isSearchHost(url.hostname) && !heading) continue;
          const container = anchor.closest('article,li,div') || anchor.parentElement;
          let snippet = clean(container?.innerText || '');
          if (snippet.startsWith(title)) snippet = snippet.substring(title.length).trim();
          if (snippet.length > 300) snippet = snippet.substring(0, 300);
          seen.add(href);
          out.push({title, url: href, snippet});
          if (out.length >= 24) break;
        }
        return JSON.stringify(out);
      })();
    ''');

    if (!mounted) return;
    try {
      final text = raw?.toString() ?? '[]';
      final decoded = jsonDecode(text) as List<dynamic>;
      final results = decoded
          .whereType<Map>()
          .map((item) => _RadSearchResult(
                title: item['title']?.toString().trim() ?? '',
                url: item['url']?.toString().trim() ?? '',
                snippet: item['snippet']?.toString().trim() ?? '',
              ))
          .where((item) => item.title.isNotEmpty && item.url.startsWith('http'))
          .toList(growable: false);
      setState(() {
        _results = results;
        _loading = false;
        _error = results.isEmpty ? 'نتیجه‌ای دریافت نشد؛ دوباره تلاش کنید.' : null;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'نتیجه‌ها قابل پردازش نبودند؛ دوباره تلاش کنید.';
      });
    }
  }

  void _openResult(_RadSearchResult result) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BrowserPage(initialInput: result.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: _reloadSearch,
          decoration: InputDecoration(
            hintText: 'جستجو در وب',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'جستجو',
              onPressed: () => _reloadSearch(_searchController.text),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            isDense: true,
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _reloadSearch(_query),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        widget.engine.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_results.isNotEmpty)
                      Text(
                        '${_results.length} نتیجه',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_loading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 16),
                  Text(
                    'در حال جستجو برای «$_query»…',
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ] else if (_error != null) ...[
                  const SizedBox(height: 56),
                  Icon(Icons.search_off_rounded, size: 42, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _reloadSearch(_query),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('تلاش دوباره'),
                    ),
                  ),
                ] else
                  ..._results.map(
                    (result) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => _openResult(result),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(alpha: .5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.host,
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                result.title,
                                textDirection: TextDirection.rtl,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                              ),
                              if (result.snippet.isNotEmpty) ...[
                                const SizedBox(height: 7),
                                Text(
                                  result.snippet,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: .01,
                child: SizedBox(
                  width: 2,
                  height: 2,
                  child: InAppWebView(
                    key: ValueKey('${widget.engine.name}:$_generation'),
                    initialUrlRequest: URLRequest(
                      url: WebUri(_providerUri().toString()),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      mediaPlaybackRequiresUserGesture: true,
                      supportZoom: false,
                    ),
                    onWebViewCreated: (controller) => _controller = controller,
                    onLoadStop: (controller, _) => _onProviderLoaded(controller),
                    onReceivedError: (_, request, __) {
                      if (request.isForMainFrame != true || !mounted) return;
                      setState(() {
                        _loading = false;
                        _error = 'ارتباط با موتور جستجو برقرار نشد.';
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadSearchResult {
  const _RadSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });

  final String title;
  final String url;
  final String snippet;

  String get host => Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;
}
