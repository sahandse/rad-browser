import 'package:flutter/material.dart';

import '../../../network/domain/network_mode.dart';
import '../widgets/network_status_chip.dart';
import '../widgets/rad_search_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _shortcuts = <({IconData icon, String label})>[
    (icon: Icons.language_rounded, label: 'ایران وب'),
    (icon: Icons.account_balance_rounded, label: 'بانک‌ها'),
    (icon: Icons.apartment_rounded, label: 'دولت'),
    (icon: Icons.newspaper_rounded, label: 'خبر'),
    (icon: Icons.shopping_bag_rounded, label: 'خرید'),
    (icon: Icons.school_rounded, label: 'آموزش'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'منو',
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                      const Spacer(),
                      const NetworkStatusChip(mode: NetworkMode.fullInternet),
                    ],
                  ),
                  const SizedBox(height: 54),
                  _RadMark(theme: theme),
                  const SizedBox(height: 30),
                  RadSearchBar(onSubmitted: (_) {}),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 18,
                    children: _shortcuts
                        .map(
                          (item) => _Shortcut(
                            icon: item.icon,
                            label: item.label,
                            onTap: () {},
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 46),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('افزودن میانبر'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_rounded)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_rounded)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.home_rounded)),
              Badge(
                label: const Text('1'),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.crop_square_rounded),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.menu_rounded)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadMark extends StatelessWidget {
  const _RadMark({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Text(
            'R',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'راد',
          textDirection: TextDirection.rtl,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 74,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: .55),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
