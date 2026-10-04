import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../browser/presentation/pages/browser_page.dart';
import '../../../network/presentation/network_providers.dart';
import '../../../search/presentation/search_providers.dart';
import '../../domain/iran_site.dart';

class IranDirectoryPage extends ConsumerStatefulWidget {
  const IranDirectoryPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<IranDirectoryPage> createState() => _IranDirectoryPageState();
}

class _IranDirectoryPageState extends ConsumerState<IranDirectoryPage> {
  late String _query;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(iranDirectoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ایران وب'),
      ),
      body: SafeArea(
        child: directory.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DirectoryError(
            onRetry: () => ref.invalidate(iranDirectoryProvider),
          ),
          data: (sites) {
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? sites
                : sites.where((site) {
                    final haystack = [
                      site.name,
                      site.url.host,
                      ...site.keywords,
                    ].join(' ').toLowerCase();
                    return haystack.contains(q);
                  }).toList(growable: false);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: SearchBar(
                    controller: _controller,
                    hintText: 'جستجو در سایت‌های ایرانی',
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          tooltip: 'پاک کردن',
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _NoLocalResult(query: _query)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final site = filtered[index];
                            return _SiteTile(site: site);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoLocalResult extends StatelessWidget {
  const _NoLocalResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 44,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'در فهرست محلی نتیجه‌ای پیدا نشد',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'می‌توانید عبارت را با ذره‌بین جستجو کنید. دسترسی به نتیجه‌ها به وضعیت واقعی شبکه داخلی بستگی دارد.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  final value = query.trim();
                  if (value.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: value));
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BrowserPage(
                        initialInput: 'https://zarebin.ir/',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.search_rounded),
                label: Text(
                  query.trim().isEmpty
                      ? 'باز کردن ذره‌بین'
                      : 'کپی عبارت و باز کردن ذره‌بین',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiteTile extends ConsumerWidget {
  const _SiteTile({required this.site});

  final IranSite site;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reachable = ref.watch(siteReachabilityProvider(site.url));
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        child: Text(
          site.name.characters.first,
          textDirection: TextDirection.rtl,
        ),
      ),
      title: Text(
        site.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        site.url.host,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: reachable.when(
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
        error: (_, __) => Icon(
          Icons.circle_outlined,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
        data: (value) => Tooltip(
          message: value ? 'در دسترس' : 'در دسترس نیست',
          child: Icon(
            Icons.circle,
            size: 12,
            color: value ? scheme.primary : scheme.outline,
          ),
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BrowserPage(initialInput: site.url.toString()),
        ),
      ),
    );
  }
}

class _DirectoryError extends StatelessWidget {
  const _DirectoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 42),
          const SizedBox(height: 12),
          const Text('خطا در خواندن فهرست سایت‌ها'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تلاش دوباره'),
          ),
        ],
      ),
    );
  }
}
