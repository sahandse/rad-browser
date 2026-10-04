import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/browser_tab.dart';
import '../../domain/tab_group.dart';
import '../controllers/browser_tabs_controller.dart';
import '../controllers/tab_groups_controller.dart';
import 'browser_page.dart';
import 'private_browser_page.dart';

class TabsPage extends ConsumerWidget {
  const TabsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(browserTabsProvider);
    final groups = ref.watch(tabGroupsProvider);
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
          IconButton(
            tooltip: 'گروه جدید',
            onPressed: () => _createGroup(context, ref),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          if (tabs.isNotEmpty)
            IconButton(
              tooltip: 'بستن همه تب‌ها',
              onPressed: () => ref.read(browserTabsProvider.notifier).closeAll(),
              icon: const Icon(Icons.close_rounded),
            ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTabMenu(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تب جدید'),
      ),
      body: tabs.isEmpty
          ? _EmptyTabs(scheme: scheme, theme: theme)
          : _GroupedTabs(
              tabs: tabs,
              groups: groups,
              onOpen: (tab) => _openTab(context, tab),
              onClose: (tab) =>
                  ref.read(browserTabsProvider.notifier).close(tab.id),
              onManage: (tab) => _manageTab(context, ref, tab, groups),
              onGroupMenu: (group) =>
                  _manageGroup(context, ref, group),
            ),
    );
  }

  void _openTab(BuildContext context, BrowserTab tab) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BrowserPage(
          initialInput: tab.url.toString(),
          existingTabId: tab.id,
        ),
      ),
    );
  }

  Future<void> _createGroup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('گروه جدید'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'مثلاً مطالعه، خرید یا کار',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('ساخت'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    await ref.read(tabGroupsProvider.notifier).create(title);
  }

  Future<void> _manageTab(
    BuildContext context,
    WidgetRef ref,
    BrowserTab tab,
    List<TabGroup> groups,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('انتقال به گروه'),
                subtitle: Text(
                  tab.groupId == null
                      ? 'بدون گروه'
                      : groups
                              .where((group) => group.id == tab.groupId)
                              .map((group) => group.title)
                              .firstOrNull ??
                          'گروه حذف‌شده',
                ),
              ),
              if (tab.groupId != null)
                ListTile(
                  leading: const Icon(Icons.folder_off_outlined),
                  title: const Text('حذف از گروه'),
                  onTap: () {
                    ref
                        .read(browserTabsProvider.notifier)
                        .moveToGroup(tab.id, null);
                    Navigator.pop(sheetContext);
                  },
                ),
              for (final group in groups)
                ListTile(
                  leading: Icon(
                    group.id == tab.groupId
                        ? Icons.folder_rounded
                        : Icons.folder_outlined,
                  ),
                  title: Text(group.title),
                  trailing: group.id == tab.groupId
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    ref
                        .read(browserTabsProvider.notifier)
                        .moveToGroup(tab.id, group.id);
                    Navigator.pop(sheetContext);
                  },
                ),
              if (groups.isEmpty)
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('اول یک گروه بسازید'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _createGroup(context, ref);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _manageGroup(
    BuildContext context,
    WidgetRef ref,
    TabGroup group,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('تغییر نام گروه'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final controller = TextEditingController(text: group.title);
                  final value = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('تغییر نام گروه'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        onSubmitted: (value) =>
                            Navigator.pop(dialogContext, value),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('انصراف'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, controller.text),
                          child: const Text('ذخیره'),
                        ),
                      ],
                    ),
                  );
                  controller.dispose();
                  if (value != null && value.trim().isNotEmpty) {
                    await ref
                        .read(tabGroupsProvider.notifier)
                        .rename(group.id, value);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('حذف گروه'),
                subtitle: const Text('تب‌ها بسته نمی‌شوند؛ فقط از گروه خارج می‌شوند.'),
                onTap: () async {
                  ref
                      .read(browserTabsProvider.notifier)
                      .removeGroupMembership(group.id);
                  await ref.read(tabGroupsProvider.notifier).remove(group.id);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
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

class _GroupedTabs extends StatelessWidget {
  const _GroupedTabs({
    required this.tabs,
    required this.groups,
    required this.onOpen,
    required this.onClose,
    required this.onManage,
    required this.onGroupMenu,
  });

  final List<BrowserTab> tabs;
  final List<TabGroup> groups;
  final ValueChanged<BrowserTab> onOpen;
  final ValueChanged<BrowserTab> onClose;
  final ValueChanged<BrowserTab> onManage;
  final ValueChanged<TabGroup> onGroupMenu;

  @override
  Widget build(BuildContext context) {
    final ungrouped = tabs.where((tab) => tab.groupId == null).toList();
    final sections = <Widget>[];

    if (ungrouped.isNotEmpty) {
      sections.add(
        _TabSection(
          title: 'بدون گروه',
          tabs: ungrouped,
          onOpen: onOpen,
          onClose: onClose,
          onManage: onManage,
        ),
      );
    }

    for (final group in groups) {
      final groupTabs = tabs.where((tab) => tab.groupId == group.id).toList();
      sections.add(
        _TabSection(
          title: group.title,
          tabs: groupTabs,
          group: group,
          onOpen: onOpen,
          onClose: onClose,
          onManage: onManage,
          onGroupMenu: onGroupMenu,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, index) => sections[index],
    );
  }
}

class _TabSection extends StatelessWidget {
  const _TabSection({
    required this.title,
    required this.tabs,
    required this.onOpen,
    required this.onClose,
    required this.onManage,
    this.group,
    this.onGroupMenu,
  });

  final String title;
  final List<BrowserTab> tabs;
  final TabGroup? group;
  final ValueChanged<BrowserTab> onOpen;
  final ValueChanged<BrowserTab> onClose;
  final ValueChanged<BrowserTab> onManage;
  final ValueChanged<TabGroup>? onGroupMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (group != null)
              Icon(Icons.folder_rounded, size: 19, color: scheme.primary),
            if (group != null) const SizedBox(width: 7),
            Expanded(
              child: Text(
                '$title  ·  ${tabs.length}',
                textDirection: TextDirection.rtl,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (group != null)
              IconButton(
                tooltip: 'مدیریت گروه',
                visualDensity: VisualDensity.compact,
                onPressed: () => onGroupMenu?.call(group!),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (tabs.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'این گروه هنوز تبی ندارد.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 650
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth < 420 ? .95 : 1.12,
                ),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  return _TabCard(
                    title: tab.title,
                    host: tab.url.host,
                    loading: tab.isLoading,
                    progress: tab.progress,
                    onTap: () => onOpen(tab),
                    onClose: () => onClose(tab),
                    onManage: () => onManage(tab),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _EmptyTabs extends StatelessWidget {
  const _EmptyTabs({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    required this.onManage,
  });

  final String title;
  final String host;
  final bool loading;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onManage;

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
        onLongPress: onManage,
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
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
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
                      tooltip: 'انتقال یا مدیریت تب',
                      visualDensity: VisualDensity.compact,
                      onPressed: onManage,
                      icon: const Icon(Icons.more_horiz_rounded, size: 19),
                    ),
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
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
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
