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
  String? _category;
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
      appBar: AppBar(title: const Text('ایران وب')),
      body: SafeArea(
        child: directory.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DirectoryError(
            onRetry: () => ref.invalidate(iranDirectoryProvider),
          ),
          data: (sites) {
            final q = _query.trim().toLowerCase();
            final categories = <String>{
              for (final site in sites) site.category,
            }.toList(growable: false)
              ..sort((a, b) => _categoryOrder(a).compareTo(_categoryOrder(b)));
            final filtered = sites.where((site) {
              if (_category != null && site.category != _category) return false;
              if (q.isEmpty) return true;
              final haystack = [
                site.name,
                site.url.host,
                _categoryTitle(site.category),
                site.description,
                ...site.keywords,
                ...site.features,
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
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('همه'),
                          selected: _category == null,
                          onSelected: (_) => setState(() => _category = null),
                        ),
                      ),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(_categoryTitle(category)),
                            selected: _category == category,
                            onSelected: (_) => setState(() => _category = category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} سایت',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Spacer(),
                      if (_category != null)
                        Text(
                          _categoryTitle(_category!),
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _NoLocalResult(query: _query)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => _SiteTile(site: filtered[index]),
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
              Icon(Icons.travel_explore_rounded, size: 44, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'در فهرست محلی نتیجه‌ای پیدا نشد',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                      builder: (_) => const BrowserPage(initialInput: 'https://zarebin.ir/'),
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      leading: CircleAvatar(
        child: Text(site.name.characters.first, textDirection: TextDirection.rtl),
      ),
      title: Text(
        site.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (site.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              site.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _categoryTitle(site.category),
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                site.url.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
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


String _categoryTitle(String id) => switch (id) {
      'search' => 'جستجو',
      'government' => 'دولت و خدمات عمومی',
      'banking' => 'بانک و پرداخت',
      'shopping' => 'فروشگاه و خرید',
      'news' => 'خبر و رسانه',
      'education' => 'آموزش و دانشگاه',
      'transport' => 'حمل‌ونقل و سفر',
      'map' => 'نقشه و مسیریابی',
      'weather' => 'هواشناسی',
      'health' => 'سلامت و درمان',
      'video' => 'ویدیو و سرگرمی',
      'communication' => 'پیام‌رسان و ارتباطات',
      'operator' => 'اپراتورها و اینترنت',
      'technology' => 'فناوری و خدمات آنلاین',
      'insurance' => 'بیمه',
      'hospital' => 'بیمارستان و مراکز درمانی',
      'downloads' => 'دانلود و اپلیکیشن',
      'hosting' => 'هاستینگ و کسب‌وکار',
      'taxi' => 'تاکسی و پیک اینترنتی',
      'ai' => 'هوش مصنوعی',
      'music' => 'موسیقی و پادکست',
      'food' => 'سفارش غذا',
      'books' => 'کتاب و کتابخوان',
      'travel' => 'بلیت و گردشگری',
      'discount' => 'تخفیف',
      'jobs' => 'کاریابی',
      'email' => 'ایمیل',
      'dictionary' => 'دیکشنری و ترجمه',
      'sports' => 'ورزش',
      'upload' => 'آپلود فایل',
      'classifieds' => 'نیازمندی‌ها',
      'utilities' => 'خدمات کاربردی',
      _ => 'سایر خدمات',
    };

int _categoryOrder(String id) => switch (id) {
      'search' => 1,
      'government' => 2,
      'banking' => 3,
      'shopping' => 4,
      'news' => 5,
      'education' => 6,
      'transport' => 7,
      'map' => 8,
      'weather' => 9,
      'health' => 10,
      'video' => 11,
      'communication' => 12,
      'operator' => 13,
      'technology' => 14,
      'insurance' => 15,
      'hospital' => 16,
      'downloads' => 17,
      'hosting' => 18,
      'taxi' => 19,
      'ai' => 20,
      'music' => 21,
      'food' => 22,
      'books' => 23,
      'travel' => 24,
      'discount' => 25,
      'jobs' => 26,
      'email' => 27,
      'dictionary' => 28,
      'sports' => 29,
      'upload' => 30,
      'classifieds' => 31,
      'utilities' => 32,
      _ => 99,
    };
