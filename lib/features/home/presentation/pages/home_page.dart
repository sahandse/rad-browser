import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../browser/presentation/pages/browser_page.dart';
import '../../../network/domain/network_mode.dart';
import '../../../network/presentation/network_providers.dart';
import '../widgets/network_status_chip.dart';
import '../widgets/rad_search_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _shortcuts = <({IconData icon, String label})>[
    (icon: Icons.language_rounded, label: 'ایران وب'),
    (icon: Icons.account_balance_outlined, label: 'بانک‌ها'),
    (icon: Icons.apartment_outlined, label: 'دولت'),
    (icon: Icons.newspaper_outlined, label: 'خبر'),
    (icon: Icons.shopping_bag_outlined, label: 'خرید'),
    (icon: Icons.school_outlined, label: 'آموزش'),
  ];

  void _openBrowser(BuildContext context, String input) {
    if (input.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BrowserPage(initialInput: input)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final network = ref.watch(networkModeProvider);
    final mode = network.valueOrNull;
    final internalOnly = mode == NetworkMode.internalOnly;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'منو',
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: mode == null
                            ? const _NetworkCheckingChip()
                            : NetworkStatusChip(key: ValueKey(mode), mode: mode),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).height < 700 ? 34 : 62),
                  _RadMark(theme: theme),
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: internalOnly
                        ? Text(
                            'شبکه داخلی فعال است',
                            key: const ValueKey('internal-title'),
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('normal-title')),
                  ),
                  if (internalOnly) const SizedBox(height: 14),
                  RadSearchBar(
                    onSubmitted: (value) => _openBrowser(context, value),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
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
                  const SizedBox(height: 40),
                  Divider(color: scheme.outlineVariant.withValues(alpha: .5), height: 1),
                  const SizedBox(height: 18),
                  Text(
                    internalOnly
                        ? 'جستجو و باز کردن سایت‌های در دسترس ایران ادامه دارد.'
                        : 'راد برای وب سریع، خلوت و قابل‌اعتماد طراحی شده است.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: null, icon: const Icon(Icons.arrow_back_rounded)),
              IconButton(onPressed: null, icon: const Icon(Icons.arrow_forward_rounded)),
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

class _NetworkCheckingChip extends StatelessWidget {
  const _NetworkCheckingChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.7, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          const Text('بررسی شبکه', textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}

class _RadMark extends StatelessWidget {
  const _RadMark({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.primary.withValues(alpha: .72)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: .18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'R',
            style: TextStyle(
              color: Colors.white,
              fontSize: 37,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'راد',
          textDirection: TextDirection.rtl,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: 76,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: .58),
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: .28)),
                ),
                child: Icon(icon, size: 21, color: scheme.onSurface),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
