import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/controllers/bookmarks_controller.dart';
import '../../../browser/presentation/controllers/browser_tabs_controller.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../permissions/presentation/pages/site_permissions_page.dart';
import '../../../sync/presentation/pages/backup_sync_page.dart';
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
                  settings.uiDensity == RadUiDensity.compact ? 'فشرده' : 'راحت',
                ),
                onTap: () => _showDensityPicker(context, ref, settings.uiDensity),
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
          _SectionTitle(title: 'حریم خصوصی و امنیت', theme: theme),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('محافظت در برابر رهگیری'),
                subtitle: Text(settings.trackingProtection.title),
                onTap: () => _showTrackingPicker(
                  context,
                  ref,
                  settings.trackingProtection,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.https_rounded),
                title: const Text('HTTPS-first'),
                subtitle: const Text(
                  'برای آدرس‌های HTTP ابتدا نسخه امن HTTPS امتحان شود.',
                ),
                value: settings.httpsFirst,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).setHttpsFirst(value),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.open_in_new_off_rounded),
                title: const Text('مسدود کردن Pop-up'),
                subtitle: const Text(
                  'پنجره‌های ناخواسته و بازشدن خودکار تب‌ها محدود می‌شوند.',
                ),
                value: settings.blockPopups,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).setBlockPopups(value),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.data_saver_on_rounded),
                title: const Text('کاهش مصرف داده'),
                subtitle: const Text(
                  'پخش خودکار و بارگذاری‌های سنگین غیرضروری محدود می‌شوند.',
                ),
                value: settings.dataSaver,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).setDataSaver(value),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('مجوزهای سایت‌ها'),
                subtitle: const Text('دوربین، میکروفون، موقعیت و اعلان‌ها'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SitePermissionsPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionTitle(title: 'انتقال و پشتیبان', theme: theme),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.sync_alt_rounded),
                title: const Text('Android ↔ Web'),
                subtitle: const Text(
                  'ساخت و بازیابی فایل پشتیبان نسخه‌دار بدون وابستگی به سرور خارجی',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BackupSyncPage(),
                  ),
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
                (value) => _ChoiceTile(
                  title: _themeLabel(value),
                  selected: value == selected,
                  onTap: () => Navigator.pop(context, value),
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
            _ChoiceTile(
              title: 'راحت',
              subtitle: 'فاصله بیشتر برای استفاده لمسی',
              selected: selected == RadUiDensity.comfortable,
              onTap: () => Navigator.pop(context, RadUiDensity.comfortable),
            ),
            _ChoiceTile(
              title: 'فشرده',
              subtitle: 'فضای بیشتر برای محتوای وب',
              selected: selected == RadUiDensity.compact,
              onTap: () => Navigator.pop(context, RadUiDensity.compact),
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
                (value) => _ChoiceTile(
                  title: value.title,
                  selected: value == selected,
                  onTap: () => Navigator.pop(context, value),
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

  Future<void> _showTrackingPicker(
    BuildContext context,
    WidgetRef ref,
    RadTrackingProtection selected,
  ) async {
    final result = await showModalBottomSheet<RadTrackingProtection>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RadTrackingProtection.values
              .map(
                (value) => _ChoiceTile(
                  title: value.title,
                  subtitle: value.description,
                  selected: value == selected,
                  onTap: () => Navigator.pop(context, value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setTrackingProtection(result);
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

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
      selected: selected,
      onTap: onTap,
    );
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
