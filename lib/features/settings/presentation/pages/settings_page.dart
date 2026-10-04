import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/controllers/bookmarks_controller.dart';
import '../../../browser/presentation/controllers/browser_tabs_controller.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../domain/app_settings.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle(title: 'ظاهر', theme: theme),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('تم'),
                subtitle: Text(_themeLabel(settings.theme)),
                onTap: () => _showThemePicker(context, ref, settings.theme),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.density_medium_rounded),
                title: const Text('تراکم رابط'),
                subtitle: Text(
                  settings.uiDensity == RadUiDensity.compact
                      ? 'فشرده'
                      : 'راحت',
                ),
                onTap: () => _showDensityPicker(
                  context,
                  ref,
                  settings.uiDensity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionTitle(title: 'جستجو', theme: theme),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.search_rounded),
                title: const Text('موتور جستجو'),
                subtitle: Text(settings.searchEngine.title),
                onTap: () => _showSearchEnginePicker(
                  context,
                  ref,
                  settings.searchEngine,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionTitle(title: 'داده‌های مرور', theme: theme),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('پاک کردن تاریخچه'),
                onTap: () => _confirmAndRun(
                  context,
                  title: 'تاریخچه پاک شود؟',
                  message: 'تمام تاریخچه مرور ذخیره‌شده روی این دستگاه پاک می‌شود.',
                  action: () => ref.read(historyProvider.notifier).clear(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.tab_unselected_rounded),
                title: const Text('بستن همه تب‌ها'),
                onTap: () => _confirmAndRun(
                  context,
                  title: 'همه تب‌ها بسته شوند؟',
                  message: 'تمام تب‌های ذخیره‌شده بسته می‌شوند.',
                  action: () async =>
                      ref.read(browserTabsProvider.notifier).closeAll(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star_border_rounded),
                title: const Text('پاک کردن نشانک‌ها'),
                onTap: () => _confirmAndRun(
                  context,
                  title: 'نشانک‌ها پاک شوند؟',
                  message: 'تمام نشانک‌های ذخیره‌شده حذف می‌شوند.',
                  action: () => ref.read(bookmarksProvider.notifier).clear(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _themeLabel(RadThemePreference value) => switch (value) {
        RadThemePreference.system => 'مطابق سیستم',
        RadThemePreference.light => 'روشن',
        RadThemePreference.dark => 'تیره',
      };

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    RadThemePreference selected,
  ) async {
    final result = await showModalBottomSheet<RadThemePreference>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RadThemePreference.values
              .map(
                (value) => RadioListTile<RadThemePreference>(
                  value: value,
                  groupValue: selected,
                  title: Text(_themeLabel(value)),
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setTheme(result);
    }
  }

  Future<void> _showDensityPicker(
    BuildContext context,
    WidgetRef ref,
    RadUiDensity selected,
  ) async {
    final result = await showModalBottomSheet<RadUiDensity>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<RadUiDensity>(
              value: RadUiDensity.comfortable,
              groupValue: selected,
              title: const Text('راحت'),
              subtitle: const Text('فاصله بیشتر برای استفاده لمسی'),
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<RadUiDensity>(
              value: RadUiDensity.compact,
              groupValue: selected,
              title: const Text('فشرده'),
              subtitle: const Text('فضای بیشتر برای محتوای وب'),
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setUiDensity(result);
    }
  }

  Future<void> _showSearchEnginePicker(
    BuildContext context,
    WidgetRef ref,
    RadSearchEngine selected,
  ) async {
    final result = await showModalBottomSheet<RadSearchEngine>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RadSearchEngine.values
              .map(
                (value) => RadioListTile<RadSearchEngine>(
                  value: value,
                  groupValue: selected,
                  title: Text(value.title),
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setSearchEngine(result);
    }
  }

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
    if (accepted == true) await action();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
