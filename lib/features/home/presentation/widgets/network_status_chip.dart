import 'package:flutter/material.dart';

import '../../../../core/theme/rad_theme.dart';
import '../../../network/domain/network_mode.dart';

class NetworkStatusChip extends StatelessWidget {
  const NetworkStatusChip({super.key, required this.mode});

  final NetworkMode mode;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (mode) {
      NetworkMode.fullInternet => (Icons.public_rounded, RadColors.primary),
      NetworkMode.internalOnly => (Icons.flag_rounded, RadColors.internal),
      NetworkMode.offline => (Icons.cloud_off_rounded, RadColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            mode.title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
