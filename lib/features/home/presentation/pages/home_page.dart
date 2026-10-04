import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/pages/bookmarks_page.dart';
import '../../../browser/presentation/controllers/browser_tabs_controller.dart';
import '../../../browser/presentation/pages/browser_page.dart';
import '../../../browser/presentation/pages/tabs_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../network/domain/network_mode.dart';
import '../../../network/presentation/network_providers.dart';
import '../widgets/network_status_chip.dart';
import '../widgets/rad_search_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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
    final tabCount = ref.watch(browserTabsProvider).length;

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
                        onPressed: () => _showHomeMenu(context),
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
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height < 700 ? 52 : 82,
                  ),
                  _RadMark(theme: theme),
                  const SizedBox(height: 34),
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
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HomeAction(
                        icon: Icons.star_border_rounded,
                        label: 'نشانک‌ها',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BookmarksPage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      _HomeAction(
                        icon: Icons.history_rounded,
                        label: 'تاریخچه',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HistoryPage(),
                          ),
                        ),
                      ),
                    ],
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
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .45),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const IconButton(
                tooltip: 'عقب',
                onPressed: null,
                icon: Icon(Icons.arrow_back_rounded),
              ),
              const IconButton(
                tooltip: 'جلو',
                onPressed: null,
                icon: Icon(Icons.arrow_forward_rounded),
              ),
              IconButton(
                tooltip: 'خانه',
                onPressed: () {},
                icon: const Icon(Icons.home_rounded),
              ),
              Badge(
                isLabelVisible: tabCount > 0,
                label: Text('$tabCount'),
                child: IconButton(
                  tooltip: 'تب‌ها',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TabsPage()),
                  ),
                  icon: const Icon(Icons.crop_square_rounded),
                ),
              ),
              IconButton(
                tooltip: 'منو',
                onPressed: () => _showHomeMenu(context),
                icon: const Icon(Icons.menu_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHomeMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star_border_rounded),
                title: const Text('نشانک‌ها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const BookmarksPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('تاریخچه'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.crop_square_rounded),
                title: const Text('تب‌ها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TabsPage()),
                  );
                },
              ),
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
            child: CircularProgressIndicator(
              strokeWidth: 1.7,
              color: scheme.primary,
            ),
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

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: .58),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 21),
            ),
            const SizedBox(height: 8),
            Text(label, textDirection: TextDirection.rtl),
          ],
        ),
      ),
    );
  }
}
