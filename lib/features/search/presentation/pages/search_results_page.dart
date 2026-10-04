import 'package:flutter/material.dart';

import '../../../browser/presentation/pages/browser_page.dart';
import '../../../settings/domain/app_settings.dart';
import '../../data/rad_search_service.dart';

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
  late final RadSearchService _service;
  late String _query;
  List<RadSearchItem> _results = const [];
  bool _loading = true;
  String? _error;
  RadSearchEngine? _usedEngine;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _query = widget.query.trim();
    _searchController = TextEditingController(text: _query);
    _service = RadSearchService();
    _search(_query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;
    final generation = ++_generation;
    setState(() {
      _query = value;
      _loading = true;
      _error = null;
      _results = const [];
      _usedEngine = null;
    });
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final response = await _service.search(query: value, engine: widget.engine);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = response.results;
        _usedEngine = response.usedEngine;
        _loading = false;
        _error = response.results.isEmpty
            ? 'نتیجه‌ای پیدا نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.'
            : null;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'دریافت نتایج جستجو ممکن نشد. دوباره تلاش کنید.';
      });
    }
  }

  void _openResult(RadSearchItem result) {
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
    final usedEngine = _usedEngine;
    final usedFallback = usedEngine != null && usedEngine != widget.engine;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'جستجو در وب',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'جستجو',
              onPressed: () => _search(_searchController.text),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            isDense: true,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _search(_query),
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
            if (usedFallback) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.engine.title} نتیجه قابل استفاده برنگرداند؛ راد از ${usedEngine.title} به‌عنوان موتور پشتیبان استفاده کرد.',
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  onPressed: () => _search(_query),
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
    );
  }
}
