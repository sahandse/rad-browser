import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/browser_tabs_controller.dart';
import 'browser_page.dart';
import 'private_browser_page.dart';

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
        title: Text(
          tabs.isEmpty ? 'تب‌ها' : '${tabs.length} تب',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          if (tabs.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(browserTabsProvider.notifier).closeAll(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('بستن همه'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTabMenu(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تب جدید'),
      ),
      body: tabs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tab_unselected_rounded,
                        size: 30,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'تبی باز نیست',
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'تب عادی یا خصوصی باز کنید و مرور را شروع کنید.',
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 4
                    : constraints.maxWidth >= 720
                        ? 3
                        : 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth < 420 ? .92 : 1.08,
                  ),
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    return _TabCard(
                      title: tab.title,
                      host: tab.url.host,
                      loading: tab.isLoading,
                      progress: tab.progress,
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
                      onClose: () => ref
                          .read(browserTabsProvider.notifier)
                          .close(tab.id),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _showNewTabMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('تب عادی جدید'),
                subtitle: const Text('تاریخچه و نشست مرور ذخیره می‌شود.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_rounded),
                title: const Text('تب خصوصی جدید'),
                subtitle: const Text('بدون ثبت تاریخچه و بدون بازیابی نشست.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivateBrowserPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  const _TabCard({
    required this.title,
    required this.host,
    required this.loading,
    required this.progress,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final String host;
  final bool loading;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = host.isEmpty ? 'R' : host.characters.first.toUpperCase();

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .42),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'بستن تب',
                      visualDensity: VisualDensity.compact,
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: loading ? 3 : 0,
                child: loading
                    ? LinearProgressIndicator(
                        value: progress > 0 && progress < 1 ? progress : null,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
