import 'package:flutter/material.dart';

import '../../../browser/presentation/pages/browser_page.dart';
import '../../../iran_directory/presentation/pages/iran_directory_page.dart';
import '../../../settings/domain/app_settings.dart';
import '../../data/rad_search_service.dart';
import '../../data/rad_smart_search_service.dart';

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

enum _SearchSection { all, images, videos, news }

class _RadSearchResultsPageState extends State<RadSearchResultsPage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final FocusNode _searchFocus;
  late final RadSearchService _service;
  late final RadSmartSearchService _smartService;
  late String _query;

  List<RadSearchItem> _results = const [];
  List<RadMediaItem> _images = const [];
  List<RadMediaItem> _videos = const [];
  List<RadNewsItem> _news = const [];
  List<String> _suggestions = const [];
  List<String> _related = const [];
  RadKnowledgeCard? _knowledge;
  RadAnswerBox? _answer;
  bool _loading = true;
  bool _mediaLoading = true;
  bool _newsLoading = true;
  bool _suggestionsLoading = false;
  bool _showSuggestions = false;
  String? _error;
  RadSearchEngine? _usedEngine;
  _SearchSection _section = _SearchSection.all;
  int _generation = 0;
  int _visibleResults = 20;
  int _page = 0;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _query = widget.query.trim();
    _searchController = TextEditingController(text: _query);
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchFocus = FocusNode()..addListener(_onFocusChanged);
    _service = RadSearchService();
    _smartService = RadSmartSearchService();
    _search(_query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _showSuggestions = _searchFocus.hasFocus);
    if (_searchFocus.hasFocus) {
      _updateSuggestions(_searchController.text);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _section != _SearchSection.all) return;
    if (_scrollController.position.extentAfter > 520) return;
    if (_visibleResults < _results.length) {
      setState(() => _visibleResults = (_visibleResults + 10).clamp(0, _results.length));
      return;
    }
    if (_hasMore && !_loadingMore) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _query.isEmpty) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final response = await _service.search(
        query: _query,
        engine: widget.engine,
        page: nextPage,
      );
      if (!mounted || generation != _generation) return;
      final existing = _results.map((e) => e.url).toSet();
      final incoming = response.results.where((e) => !existing.contains(e.url)).toList();
      setState(() {
        _page = nextPage;
        _results = [..._results, ...incoming];
        _visibleResults = _results.length;
        _hasMore = incoming.isNotEmpty;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _updateSuggestions(String value) async {
    final clean = value.trim();
    final generation = _generation;
    if (clean.isEmpty) {
      final recent = await _smartService.recentSearches();
      if (!mounted || generation != _generation) return;
      setState(() => _suggestions = recent.take(8).toList(growable: false));
      return;
    }
    if (clean.length < 2) return;
    setState(() => _suggestionsLoading = true);
    final results = await _smartService.suggestions(clean);
    if (!mounted || generation != _generation) return;
    setState(() {
      _suggestions = results;
      _suggestionsLoading = false;
    });
  }

  Future<void> _search(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;
    final generation = ++_generation;
    setState(() {
      _query = value;
      _loading = true;
      _mediaLoading = true;
      _newsLoading = true;
      _error = null;
      _results = const [];
      _images = const [];
      _videos = const [];
      _news = const [];
      _related = const [];
      _knowledge = null;
      _answer = _smartService.answerBox(value);
      _usedEngine = null;
      _visibleResults = 20;
      _page = 0;
      _hasMore = true;
      _loadingMore = false;
      _section = _SearchSection.all;
      _showSuggestions = false;
    });
    _searchFocus.unfocus();
    await _smartService.rememberSearch(value);

    try {
      final response = await _service.search(query: value, engine: widget.engine, page: 0);
      if (!mounted || generation != _generation) return;
      final ranked = _smartService.rankResults(value, response.results);
      setState(() {
        _results = ranked;
        _usedEngine = response.usedEngine;
        _loading = false;
        _error = ranked.isEmpty
            ? 'نتیجه‌ای پیدا نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.'
            : null;
      });
      if (ranked.isNotEmpty) {
        final knowledge = await _smartService.knowledgeCard(ranked.first);
        if (mounted && generation == _generation) {
          setState(() => _knowledge = knowledge);
        }
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'دریافت نتایج جستجو ممکن نشد. دوباره تلاش کنید.';
      });
    }

    final extras = await Future.wait<dynamic>([
      _service.searchImages(value),
      _service.searchVideos(value),
      _smartService.searchNews(value),
      _smartService.suggestions(value),
    ]);
    if (!mounted || generation != _generation) return;
    setState(() {
      _images = extras[0] as List<RadMediaItem>;
      _videos = extras[1] as List<RadMediaItem>;
      _news = extras[2] as List<RadNewsItem>;
      _related = (extras[3] as List<String>)
          .where((item) => item.toLowerCase() != value.toLowerCase())
          .take(8)
          .toList(growable: false);
      _mediaLoading = false;
      _newsLoading = false;
    });
  }

  void _selectSuggestion(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(offset: value.length);
    _search(value);
  }

  void _openUrl(String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BrowserPage(initialInput: url)),
    );
  }

  void _openIranWeb() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => IranDirectoryPage(initialQuery: _query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 8,
        title: Container(
          height: 52,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
          ),
          child: TextField(
            focusNode: _searchFocus,
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            onChanged: _updateSuggestions,
            decoration: InputDecoration(
              hintText: 'جستجو در وب',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'جستجو',
                onPressed: () => _search(_searchController.text),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _SearchTabs(
                section: _section,
                onChanged: (value) => setState(() => _section = value),
                onIranWeb: _openIranWeb,
              ),
              Expanded(
                        child: Text(
                          'نتایج با ${usedEngine.title} تکمیل شدند',
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _search(_query),
                  child: switch (_section) {
                    _SearchSection.all => _buildAll(context),
                    _SearchSection.images => _buildImages(context),
                    _SearchSection.videos => _buildVideos(context),
                    _SearchSection.news => _buildNews(context),
                  },
                ),
              ),
            ],
          ),
          if (_showSuggestions && (_suggestions.isNotEmpty || _suggestionsLoading))
            Positioned(
              left: 12,
              right: 12,
              top: 2,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(20),
                color: scheme.surfaceContainerHigh,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: _suggestionsLoading && _suggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: .35)),
                          itemBuilder: (context, index) {
                            final item = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.north_west_rounded, size: 18),
                              title: Text(item, textDirection: TextDirection.rtl),
                              onTap: () => _selectSuggestion(item),
                            );
                          },
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAll(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_loading) return const _SearchSkeleton();
    if (_error != null) return _SearchError(message: _error!, onRetry: () => _search(_query));

    final visible = _results.take(_visibleResults).toList(growable: false);
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
      children: [
        if (_answer != null) ...[
          _AnswerCard(answer: _answer!),
          const SizedBox(height: 18),
        ],
        if (_knowledge != null) ...[
          _KnowledgeCard(card: _knowledge!, onOpen: () => _openUrl(_knowledge!.sourceUrl)),
          const SizedBox(height: 22),
        ],
        if (_images.isNotEmpty || _mediaLoading) ...[
          _SectionHeader(
            title: 'تصاویر',
            icon: Icons.image_outlined,
            onMore: _images.isEmpty ? null : () => setState(() => _section = _SearchSection.images),
          ),
          const SizedBox(height: 10),
          _mediaLoading
              ? const _MediaStripSkeleton()
              : _ImageStrip(items: _images.take(8).toList(), onOpen: _openUrl),
          const SizedBox(height: 26),
        ],
        ...visible.asMap().entries.expand((entry) sync* {
          final index = entry.key;
          final result = entry.value;
          yield _WebResultTile(result: result, onTap: () => _openUrl(result.url));
          if (index == 3 && (_videos.isNotEmpty || _mediaLoading)) {
            yield const SizedBox(height: 12);
            yield _SectionHeader(
              title: 'ویدیو',
              icon: Icons.play_circle_outline_rounded,
              onMore: _videos.isEmpty ? null : () => setState(() => _section = _SearchSection.videos),
            );
            yield const SizedBox(height: 10);
            yield _mediaLoading
                ? const _MediaStripSkeleton(aspectRatio: 16 / 9)
                : _VideoStrip(items: _videos.take(6).toList(), onOpen: _openUrl);
            yield const SizedBox(height: 24);
          }
          if (index == 7 && (_news.isNotEmpty || _newsLoading)) {
            yield _SectionHeader(
              title: 'خبر',
              icon: Icons.newspaper_rounded,
              onMore: _news.isEmpty ? null : () => setState(() => _section = _SearchSection.news),
            );
            yield const SizedBox(height: 8);
            yield _newsLoading
                ? const _MediaStripSkeleton(aspectRatio: 16 / 9)
                : _NewsPreview(items: _news.take(3).toList(), onOpen: _openUrl);
            yield const SizedBox(height: 24);
          }
        }),
        if (_related.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionHeader(title: 'جستجوهای مرتبط', icon: Icons.manage_search_rounded),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _related
                .map((item) => ActionChip(
                      avatar: const Icon(Icons.search_rounded, size: 16),
                      label: Text(item),
                      onPressed: () => _selectSuggestion(item),
                    ))
                .toList(growable: false),
          ),
        ],
        if (_visibleResults < _results.length) ...[
          const SizedBox(height: 18),
          Center(
            child: Text(
              'برای نتایج بیشتر به پایین بروید',
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImages(BuildContext context) {
    if (_mediaLoading) return const _SearchSkeleton(media: true);
    if (_images.isEmpty) {
      return const _EmptyMedia(icon: Icons.image_not_supported_outlined, message: 'تصویری برای این جستجو پیدا نشد.');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 3 : 2;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .82,
          ),
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final item = _images[index];
            return _ImageCard(item: item, onTap: () => _openUrl(item.sourceUrl));
          },
        );
      },
    );
  }

  Widget _buildVideos(BuildContext context) {
    if (_mediaLoading) return const _SearchSkeleton(media: true);
    if (_videos.isEmpty) {
      return const _EmptyMedia(icon: Icons.video_library_outlined, message: 'ویدیویی برای این جستجو پیدا نشد.');
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
      itemCount: _videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _videos[index];
        return _VideoCard(item: item, onTap: () => _openUrl(item.sourceUrl));
      },
    );
  }

  Widget _buildNews(BuildContext context) {
    if (_newsLoading) return const _SearchSkeleton();
    if (_news.isEmpty) {
      return const _EmptyMedia(icon: Icons.newspaper_rounded, message: 'خبر مرتبطی برای این جستجو پیدا نشد.');
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
      itemCount: _news.length,
      separatorBuilder: (_, __) => const Divider(height: 26),
      itemBuilder: (context, index) {
        final item = _news[index];
        return _NewsTile(item: item, onTap: () => _openUrl(item.url));
      },
    );
  }
}

class _SearchTabs extends StatelessWidget {
  const _SearchTabs({required this.section, required this.onChanged, required this.onIranWeb});

  final _SearchSection section;
  final ValueChanged<_SearchSection> onChanged;
  final VoidCallback onIranWeb;

  @override
  Widget build(BuildContext context) {
    final items = <(_SearchSection, IconData, String)>[
      (_SearchSection.all, Icons.search_rounded, 'همه'),
      (_SearchSection.images, Icons.image_outlined, 'تصاویر'),
      (_SearchSection.videos, Icons.play_circle_outline_rounded, 'ویدیو'),
      (_SearchSection.news, Icons.newspaper_rounded, 'خبر'),
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 7),
                child: ChoiceChip(
                  avatar: Icon(item.$2, size: 17),
                  label: Text(item.$3),
                  selected: section == item.$1,
                  onSelected: (_) => onChanged(item.$1),
                  showCheckmark: false,
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: ActionChip(
              avatar: const Icon(Icons.language_rounded, size: 17),
              label: const Text('ایران‌وب'),
              onPressed: onIranWeb,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});
  final RadAnswerBox answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer.label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(answer.value, textDirection: TextDirection.ltr, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(answer.detail, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({required this.card, required this.onOpen});
  final RadKnowledgeCard card;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.imageUrl != null && card.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  card.imageUrl!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title, textDirection: TextDirection.rtl, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(card.summary, maxLines: 5, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                  const SizedBox(height: 8),
                  Text(card.host, textDirection: TextDirection.ltr, style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebResultTile extends StatelessWidget {
  const _WebResultTile({required this.result, required this.onTap});
  final RadSearchItem result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 30,
                    height: 30,
                    color: scheme.surfaceContainerHigh,
                    child: result.faviconUrl.isEmpty
                        ? const Icon(Icons.public_rounded, size: 17)
                        : Image.network(result.faviconUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.public_rounded, size: 17)),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.host, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(result.url, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(result.title, textDirection: TextDirection.rtl, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700, height: 1.45)),
            if (result.snippet.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(result.snippet, maxLines: 3, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.65)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, this.onMore});
  final String title;
  final IconData icon;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 7),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        if (onMore != null) TextButton(onPressed: onMore, child: const Text('بیشتر')),
      ],
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.items, required this.onOpen});
  final List<RadMediaItem> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(width: 132, child: _ImageCard(item: item, onTap: () => onOpen(item.sourceUrl), compact: true));
        },
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.item, required this.onTap, this.compact = false});
  final RadMediaItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: scheme.surfaceContainerHigh),
            Image.network(item.thumbnailUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant))),
            if (!compact)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(9, 22, 9, 8),
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                  child: Text(item.host, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoStrip extends StatelessWidget {
  const _VideoStrip({required this.items, required this.onOpen});
  final List<RadMediaItem> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(width: 230, child: _VideoCard(item: item, onTap: () => onOpen(item.sourceUrl), compact: true));
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.item, required this.onTap, this.compact = false});
  final RadMediaItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: scheme.surfaceContainerHigh),
                  if (item.thumbnailUrl.isNotEmpty)
                    Image.network(item.thumbnailUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .66), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(item.host, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _NewsPreview extends StatelessWidget {
  const _NewsPreview({required this.items, required this.onOpen});
  final List<RadNewsItem> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) => _NewsTile(item: item, onTap: () => onOpen(item.url)))
          .toList(growable: false),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item, required this.onTap});
  final RadNewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(item.imageUrl!, width: 92, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  if (item.snippet.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.snippet, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaStripSkeleton extends StatelessWidget {
  const _MediaStripSkeleton({this.aspectRatio = 1});
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(width: aspectRatio > 1 ? 220 : 132, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))),
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton({this.media = false});
  final bool media;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    if (media) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: 8,
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      itemCount: 7,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 10),
            Container(width: double.infinity, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 5),
            Container(width: 250, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
          ],
        ),
      ),
    );
  }
}

class _EmptyMedia extends StatelessWidget {
  const _EmptyMedia({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Icon(icon, size: 44, color: scheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Center(child: Text(message, textDirection: TextDirection.rtl)),
      ],
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Icon(Icons.search_off_rounded, size: 44, color: scheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(message, textAlign: TextAlign.center, textDirection: TextDirection.rtl),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره')),
        ),
      ],
    );
  }
}
