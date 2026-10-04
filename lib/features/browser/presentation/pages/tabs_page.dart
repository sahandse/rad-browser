import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/browser_tabs_controller.dart';
import 'browser_page.dart';

class TabsPage extends ConsumerWidget {
  const TabsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(browserTabsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text('تب‌ها (${tabs.length})', textDirection: TextDirection.rtl),
        centerTitle: false,
        actions: [
          if (tabs.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(browserTabsProvider.notifier).closeAll(),
              child: const Text('بستن همه'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: tabs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tab_unselected_rounded, size: 42, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 14),
                  Text(
                    'تبی باز نیست',
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 600
                        ? 3
                        : 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .78,
                  ),
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    return Material(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => BrowserPage(
                                initialInput: tab.url.toString(),
                                existingTabId: tab.id,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: scheme.surfaceContainerHighest.withValues(alpha: .6),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.language_rounded,
                                  size: 42,
                                  color: scheme.onSurfaceVariant.withValues(alpha: .72),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tab.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          tab.url.host,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'بستن تب',
                                    onPressed: () => ref
                                        .read(browserTabsProvider.notifier)
                                        .close(tab.id),
                                    icon: const Icon(Icons.close_rounded, size: 19),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
