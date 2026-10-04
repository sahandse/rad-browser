import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/site_permission.dart';
import '../controllers/site_permissions_controller.dart';

class SitePermissionsPage extends ConsumerWidget {
  const SitePermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(sitePermissionsProvider).values.toList()
      ..sort((a, b) {
        final host = a.host.compareTo(b.host);
        return host != 0 ? host : a.kind.name.compareTo(b.kind.name);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('مجوزهای سایت‌ها'),
        actions: [
          if (permissions.isNotEmpty)
            TextButton(
              onPressed: () async {
                final accepted = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('بازنشانی همه مجوزها؟'),
                    content: const Text(
                      'تصمیم‌های دائمی مجوز سایت‌ها حذف می‌شوند و دوباره هنگام نیاز پرسیده می‌شود.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('انصراف'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('بازنشانی'),
                      ),
                    ],
                  ),
                );
                if (accepted == true) {
                  await ref.read(sitePermissionsProvider.notifier).clearAll();
                }
              },
              child: const Text('بازنشانی'),
            ),
        ],
      ),
      body: permissions.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 48),
                    SizedBox(height: 14),
                    Text(
                      'هنوز تصمیم دائمی برای هیچ سایتی ذخیره نشده',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
              itemCount: permissions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = permissions[index];
                return ListTile(
                  leading: Icon(_iconFor(entry.kind)),
                  title: Text(entry.host),
                  subtitle: Text(entry.kind.title),
                  trailing: DropdownButton<SitePermissionDecision>(
                    value: entry.decision,
                    underline: const SizedBox.shrink(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await ref.read(sitePermissionsProvider.notifier).setDecision(
                            entry.host,
                            entry.kind,
                            value,
                          );
                    },
                    items: SitePermissionDecision.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.title),
                          ),
                        )
                        .toList(growable: false),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(SitePermissionKind kind) => switch (kind) {
        SitePermissionKind.camera => Icons.videocam_outlined,
        SitePermissionKind.microphone => Icons.mic_none_rounded,
        SitePermissionKind.location => Icons.location_on_outlined,
        SitePermissionKind.notifications => Icons.notifications_none_rounded,
      };
}
