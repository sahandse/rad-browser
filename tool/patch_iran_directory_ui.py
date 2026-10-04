from pathlib import Path

path = Path('lib/features/iran_directory/presentation/pages/iran_directory_page.dart')
text = path.read_text(encoding='utf-8')

text = text.replace(
"  late String _query;\n  late final TextEditingController _controller;\n",
"  late String _query;\n  String? _category;\n  late final TextEditingController _controller;\n",
1,
)

old_filter = '''            final filtered = q.isEmpty
                ? sites
                : sites.where((site) {
                    final haystack = [
                      site.name,
                      site.url.host,
                      site.description,
                      ...site.keywords,
                      ...site.features,
                    ].join(' ').toLowerCase();
                    return haystack.contains(q);
                  }).toList(growable: false);
'''
new_filter = '''            final categories = <String>{
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
'''
if old_filter not in text:
    raise SystemExit('filter anchor not found')
text = text.replace(old_filter, new_filter, 1)

search_anchor = '''                Padding(
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
'''
chips = search_anchor + '''                SizedBox(
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
'''
if search_anchor not in text:
    raise SystemExit('search anchor not found')
text = text.replace(search_anchor, chips, 1)

text = text.replace(
'''          const SizedBox(height: 3),
          Text(
            site.url.host,
''',
'''          const SizedBox(height: 5),
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
''',
1,
)
text = text.replace(
'''            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
''',
'''                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
''',
1,
)

helpers = r'''

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
'''
if 'String _categoryTitle(String id)' not in text:
    text += helpers

path.write_text(text, encoding='utf-8')
print('Iran Web category filters and labels added')
