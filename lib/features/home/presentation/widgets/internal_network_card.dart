import 'package:flutter/material.dart';

class InternalNetworkCard extends StatelessWidget {
  const InternalNetworkCard({
    super.key,
    required this.onOpenZarebin,
    required this.onOpenDirectory,
  });

  final VoidCallback onOpenZarebin;
  final VoidCallback onOpenDirectory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: scheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دسترسی داخلی',
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'برای سایت‌های ایرانی از مسیرهای داخلی استفاده کن.',
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
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenZarebin,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('جستجو با ذره‌بین'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenDirectory,
                  icon: const Icon(Icons.apps_rounded),
                  label: const Text('سایت‌های ایرانی'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
