import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/site_permission.dart';

enum SitePermissionPromptResult { allowOnce, allowAlways, block }

Future<SitePermissionPromptResult> showSitePermissionPrompt(
  BuildContext context, {
  required String host,
  required SitePermissionKind kind,
}) async {
  final result = await showModalBottomSheet<SitePermissionPromptResult>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(kind),
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$host به ${kind.title} دسترسی می‌خواهد',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'می‌توانید فقط برای این بار اجازه بدهید، تصمیم را برای دفعات بعد ذخیره کنید یا دسترسی را مسدود کنید.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    SitePermissionPromptResult.allowOnce,
                  ),
                  child: const Text('فقط این بار اجازه بده'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    SitePermissionPromptResult.allowAlways,
                  ),
                  child: const Text('همیشه برای این سایت اجازه بده'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  SitePermissionPromptResult.block,
                ),
                child: const Text('مسدود کن'),
              ),
            ],
          ),
        ),
      );
    },
  );

  final decision = result ?? SitePermissionPromptResult.block;
  if (decision == SitePermissionPromptResult.block) return decision;

  final deviceAllowed = await _ensureDevicePermission(kind);
  return deviceAllowed ? decision : SitePermissionPromptResult.block;
}

Future<bool> _ensureDevicePermission(SitePermissionKind kind) async {
  if (kIsWeb) return true;

  final permission = switch (kind) {
    SitePermissionKind.camera => Permission.camera,
    SitePermissionKind.microphone => Permission.microphone,
    SitePermissionKind.location => Permission.locationWhenInUse,
    SitePermissionKind.notifications => Permission.notification,
  };

  final status = await permission.request();
  return status.isGranted || status.isLimited;
}

IconData _iconFor(SitePermissionKind kind) => switch (kind) {
      SitePermissionKind.camera => Icons.videocam_outlined,
      SitePermissionKind.microphone => Icons.mic_none_rounded,
      SitePermissionKind.location => Icons.location_on_outlined,
      SitePermissionKind.notifications => Icons.notifications_none_rounded,
    };
