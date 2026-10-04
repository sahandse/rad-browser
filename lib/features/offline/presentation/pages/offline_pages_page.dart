import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/offline_page.dart';
import '../controllers/offline_pages_controller.dart';

class OfflinePagesPage extends ConsumerWidget {
  const OfflinePagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(offlinePagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('مطالعه آفلاین')),
      body: SafeArea(
        child: pages.isEmpty
            ? const _EmptyOfflineView()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: pages.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = pages[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.article_outlined),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    subtitle: Text(
                      item.url.host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'حذف',
                      onPressed: () => ref
                          .read(offlinePagesProvider.notifier)
                          .remove(item.url),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OfflineReaderPage(page: item),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class OfflineReaderPage extends StatelessWidget {
  const OfflineReaderPage({super.key, required this.page});

  final OfflinePage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('مطالعه آفلاین')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    page.title,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    page.url.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SelectableText(
                    page.content,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOfflineView extends StatelessWidget {
  const _EmptyOfflineView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_pin_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              'هنوز صفحه‌ای ذخیره نشده',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'از منوی مرورگر، «ذخیره برای مطالعه آفلاین» را بزنید.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
