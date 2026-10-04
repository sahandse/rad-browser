import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/controllers/bookmarks_controller.dart';
import '../../../browser/presentation/controllers/browser_tabs_controller.dart';
import '../../../browser/presentation/controllers/tab_groups_controller.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../offline/presentation/controllers/offline_pages_controller.dart';
import '../../../permissions/presentation/controllers/site_permissions_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/rad_backup_service.dart';

class BackupSyncPage extends ConsumerStatefulWidget {
  const BackupSyncPage({super.key});

  @override
  ConsumerState<BackupSyncPage> createState() => _BackupSyncPageState();
}

class _BackupSyncPageState extends ConsumerState<BackupSyncPage> {
  final _service = RadBackupService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('انتقال و پشتیبان')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.sync_alt_rounded,
                  size: 34,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'انتقال واقعی بین Android و Web',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'فایل پشتیبان شامل نشانک‌ها، تاریخچه، تب‌ها و گروه‌ها، صفحات آفلاین، تنظیمات و مجوزهای سایت است. فایل‌های دانلودشده منتقل نمی‌شوند.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ActionCard(
            icon: Icons.file_upload_outlined,
            title: 'ساخت فایل پشتیبان',
            subtitle: 'یک فایل JSON نسخه‌دار از داده‌های واقعی راد ذخیره می‌شود.',
            enabled: !_busy,
            onTap: _export,
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.file_download_outlined,
            title: 'بازیابی از فایل',
            subtitle: 'فایل پشتیبان راد را از Android، Web یا فضای ابری دستگاه انتخاب کنید.',
            enabled: !_busy,
            onTap: _import,
          ),
          const SizedBox(height: 22),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('همگام‌سازی ابری خودکار'),
            subtitle: const Text(
              'زیرساخت داده آماده است؛ فعال‌سازی Sync خودکار نیاز به backend و ورود امن کاربر دارد و بدون آن به‌عنوان قابلیت فعال نمایش داده نمی‌شود.',
              textDirection: TextDirection.rtl,
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final count = await _service.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فایل پشتیبان با $count بخش داده ذخیره شد')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ساخت پشتیبان ناموفق بود: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بازیابی داده‌ها؟'),
        content: const Text(
          'داده‌های موجود با بخش‌های موجود در فایل پشتیبان به‌روزرسانی می‌شوند. دانلودهای فیزیکی دست‌نخورده می‌مانند.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('انتخاب فایل'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    setState(() => _busy = true);
    try {
      final result = await _service.importBackup();
      if (result == null) return;
      _refreshProviders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.restoredKeys} بخش از پشتیبان بازیابی شد'),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بازیابی ناموفق بود: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refreshProviders() {
    ref.invalidate(bookmarksProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(browserTabsProvider);
    ref.invalidate(tabGroupsProvider);
    ref.invalidate(offlinePagesProvider);
    ref.invalidate(sitePermissionsProvider);
    ref.invalidate(settingsProvider);
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
