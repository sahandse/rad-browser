import 'package:flutter/material.dart';

class OfflineModeCard extends StatelessWidget {
  const OfflineModeCard({
    super.key,
    required this.onOpenOfflinePages,
    required this.onOpenBookmarks,
    required this.onOpenIranDirectory,
  });

  final VoidCallback onOpenOfflinePages;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenIranDirectory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شبکه در دسترس نیست',
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'بخش‌های ذخیره‌شده راد همچنان قابل استفاده‌اند.',
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onOpenOfflinePages,
                icon: const Icon(Icons.article_outlined),
                label: const Text('مطالعه آفلاین'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenBookmarks,
                icon: const Icon(Icons.star_border_rounded),
                label: const Text('نشانک‌ها'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenIranDirectory,
                icon: const Icon(Icons.language_rounded),
                label: const Text('ایران وب'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
