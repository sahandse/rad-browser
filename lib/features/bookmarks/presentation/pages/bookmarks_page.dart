import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../browser/presentation/pages/browser_page.dart';
import '../controllers/bookmarks_controller.dart';

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(bookmarksProvider);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? entries
        : entries
            .where((item) =>
                item.title.toLowerCase().contains(q) ||
                item.url.toString().toLowerCase().contains(q))
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('نشانک‌ها')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SearchBar(
                hintText: 'جستجو در نشانک‌ها',
                leading: const Icon(Icons.search_rounded),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyBookmarks()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: const CircleAvatar(
                            child: Icon(Icons.star_rounded, size: 20),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.url.host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'حذف نشانک',
                            onPressed: () => ref
                                .read(bookmarksProvider.notifier)
                                .remove(item.url),
                            icon: const Icon(Icons.close_rounded),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BrowserPage(
                                initialInput: item.url.toString(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 46,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('هنوز نشانی ذخیره نشده'),
        ],
      ),
    );
  }
}
