import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/download_item.dart';
import '../controllers/downloads_controller.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('دانلودها')),
      body: downloads.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download_done_rounded,
                    size: 46,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('هنوز فایلی دانلود نشده'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
              itemCount: downloads.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = downloads[index];
                return _DownloadTile(item: item);
              },
            ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (icon, label) = switch (item.status) {
      DownloadStatus.queued => (Icons.schedule_rounded, 'در صف'),
      DownloadStatus.downloading => (Icons.downloading_rounded, 'در حال دانلود'),
      DownloadStatus.completed => (Icons.check_circle_rounded, 'تکمیل شد'),
      DownloadStatus.failed => (Icons.error_outline_rounded, 'ناموفق'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
            leading: CircleAvatar(child: Icon(icon, size: 21)),
            title: Text(
              item.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.status == DownloadStatus.failed && item.errorMessage != null
                  ? '$label • ${item.errorMessage}'
                  : '$label • ${item.url.host}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'retry') {
                  ref.read(downloadsProvider.notifier).retry(item.id);
                } else if (value == 'remove') {
                  ref.read(downloadsProvider.notifier).remove(item.id);
                }
              },
              itemBuilder: (context) => [
                if (item.status == DownloadStatus.failed)
                  const PopupMenuItem(
                    value: 'retry',
                    child: Text('تلاش دوباره'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('حذف از فهرست'),
                ),
              ],
            ),
          ),
          if (item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.queued)
            Padding(
              padding: const EdgeInsets.fromLTRB(70, 0, 12, 4),
              child: LinearProgressIndicator(
                value: item.progress > 0 ? item.progress : null,
                minHeight: 3,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          if (item.status == DownloadStatus.completed &&
              item.savedLocation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(70, 0, 12, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.savedLocation!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
