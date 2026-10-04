import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/url_utils.dart';
import '../../../../core/widgets/rad_brand_logo.dart';
import '../../../../core/widgets/rad_clock_header.dart';
import '../../../bookmarks/presentation/pages/bookmarks_page.dart';
import '../../../browser/presentation/controllers/browser_tabs_controller.dart';
import '../../../browser/presentation/pages/browser_page.dart';
import '../../../browser/presentation/pages/tabs_page.dart';
import '../../../downloads/presentation/pages/downloads_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../iran_directory/presentation/pages/iran_directory_page.dart';
import '../../../network/domain/network_mode.dart';
import '../../../network/presentation/network_providers.dart';
import '../../../offline/presentation/pages/offline_pages_page.dart';
import '../../../search/presentation/pages/search_results_page.dart';
import '../../../search/presentation/widgets/rad_suggesting_search_box.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _openInput(
    BuildContext context,
    WidgetRef ref,
    String input,
  ) async {
    final value = input.trim();
    if (value.isEmpty) return;

    if (value.startsWith('!')) {
      final handled = await _handleBang(context, ref, value);
      if (handled) return;
      if (!context.mounted) return;
    }

    final mode = ref.read(networkModeProvider).valueOrNull;
    if (UrlUtils.looksLikeUrl(value)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BrowserPage(initialInput: value)),
      );
      return;
    }

    if (mode == NetworkMode.internalOnly || mode == NetworkMode.offline) {
      _openIranDirectory(context, initialQuery: value);
      return;
    }

    final engine = ref.read(settingsProvider).searchEngine;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RadSearchResultsPage(query: value, engine: engine),
      ),
    );
  }

  Future<bool> _handleBang(
    BuildContext context,
    WidgetRef ref,
    String input,
  ) async {
    final firstSpace = input.indexOf(' ');
    final command = (firstSpace == -1 ? input : input.substring(0, firstSpace))
        .toLowerCase();
    final query = firstSpace == -1 ? '' : input.substring(firstSpace + 1).trim();

    switch (command) {
      case '!ir':
        _openIranDirectory(context, initialQuery: query);
        return true;
      case '!z':
        if (query.isEmpty) return false;
        if (!context.mounted) return true;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RadSearchResultsPage(
              query: query,
              engine: RadSearchEngine.zarebin,
            ),
          ),
        );
        return true;
      case '!film':
        _openDirect(context, 'https://filmcase.ir/');
        return true;
      case '!nora':
      case '!shop':
        _openDirect(context, 'https://noraashop.ir/');
        return true;
      case '!news':
        _openIranDirectory(
          context,
          initialQuery: query.isEmpty ? 'خبر' : query,
        );
        return true;
      case '!bank':
        _openIranDirectory(
          context,
          initialQuery: query.isEmpty ? 'بانک' : query,
        );
        return true;
      case '!map':
        _openIranDirectory(
          context,
          initialQuery: query.isEmpty ? 'نقشه' : query,
        );
        return true;
      default:
        return false;
    }
  }

  void _openDirect(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BrowserPage(initialInput: url)),
    );
  }

  void _openIranDirectory(
    BuildContext context, {
    String initialQuery = '',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IranDirectoryPage(initialQuery: initialQuery),
      ),
    );
  }

  void _openOfflinePages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OfflinePagesPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mode = ref.watch(networkModeProvider).valueOrNull;
    final tabCount = ref.watch(browserTabsProvider).length;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _HomeBackdrop()),
            Positioned(
              top: 10,
              left: 12,
              child: _RoundActionButton(
                tooltip: 'منو',
                icon: Icons.more_horiz_rounded,
                onTap: () => _showHomeMenu(context),
              ),
            ),
            Positioned(
              top: 12,
              right: 14,
              child: _MinimalNetworkStatus(mode: mode),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 74, 22, 116),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RadClockHeader(),
                      const SizedBox(height: 30),
                      const RadBrandLogo(size: 102),
                      const SizedBox(height: 30),
                      RadSuggestingSearchBox(
                        hint: mode == NetworkMode.internalOnly
                            ? 'جستجو در وب ایران'
                            : mode == NetworkMode.offline
                                ? 'جستجو در داده‌های ذخیره‌شده'
                                : 'جستجو یا وارد کردن آدرس',
                        onSubmitted: (value) => _openInput(context, ref, value),
                      ),
                      const SizedBox(height: 14),
                      if (mode == NetworkMode.fullInternet || mode == null)
                        _SearchEngineSelector(
                          selected: settings.searchEngine,
                          onChanged: (engine) => ref
                              .read(settingsProvider.notifier)
                              .setSearchEngine(engine),
                        ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _ModeHint(
                          key: ValueKey(mode),
                          mode: mode,
                          onIranWeb: () => _openIranDirectory(context),
                          onOffline: () => _openOfflinePages(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: _TabsButton(
                  count: tabCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TabsPage()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHomeMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          children: [
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: const Text('ایران وب'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openIranDirectory(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.offline_pin_outlined),
              title: const Text('صفحات آفلاین'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openOfflinePages(context);
              },
            ),
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
              leading: const Icon(Icons.download_rounded),
              title: const Text('دانلودها'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DownloadsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square_rounded),
              title: const Text('تب‌ها و گروه‌ها'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TabsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('تنظیمات'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 110,
            left: -90,
            child: _GlowCircle(
              size: 250,
              color: scheme.primary.withValues(alpha: .055),
            ),
          ),
          Positioned(
            top: 290,
            right: -110,
            child: _GlowCircle(
              size: 300,
              color: scheme.tertiary.withValues(alpha: .045),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _RadHomeSearchBox extends StatefulWidget {
  const _RadHomeSearchBox({
    required this.hint,
    required this.onSubmitted,
  });

  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  State<_RadHomeSearchBox> createState() => _RadHomeSearchBoxState();
}

class _RadHomeSearchBoxState extends State<_RadHomeSearchBox> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() => _focused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 64,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: _focused
              ? scheme.primary.withValues(alpha: .55)
              : scheme.outlineVariant.withValues(alpha: .52),
          width: _focused ? 1.3 : .8,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: _focused ? .085 : .045),
            blurRadius: _focused ? 32 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: widget.onSubmitted,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 7),
            child: Icon(Icons.search_rounded, size: 23, color: scheme.primary),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: IconButton.filledTonal(
              tooltip: 'جستجو',
              onPressed: () => widget.onSubmitted(_controller.text),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        ),
      ),
    );
  }
}

class _SearchEngineSelector extends StatelessWidget {
  const _SearchEngineSelector({
    required this.selected,
    required this.onChanged,
  });

  final RadSearchEngine selected;
  final ValueChanged<RadSearchEngine> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = selected == RadSearchEngine.zarebin
        ? RadSearchEngine.zarebin
        : RadSearchEngine.google;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EngineSegment(
            label: 'Google',
            selected: normalized == RadSearchEngine.google,
            onTap: () => onChanged(RadSearchEngine.google),
          ),
          _EngineSegment(
            label: 'ذره‌بین',
            selected: normalized == RadSearchEngine.zarebin,
            onTap: () => onChanged(RadSearchEngine.zarebin),
          ),
        ],
      ),
    );
  }
}

class _EngineSegment extends StatelessWidget {
  const _EngineSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: .06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow.withValues(alpha: .8),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _MinimalNetworkStatus extends StatelessWidget {
  const _MinimalNetworkStatus({required this.mode});

  final NetworkMode? mode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon) = switch (mode) {
      NetworkMode.fullInternet => ('آنلاین', Icons.circle),
      NetworkMode.internalOnly => ('شبکه داخلی', Icons.public_rounded),
      NetworkMode.offline => ('آفلاین', Icons.cloud_off_rounded),
      null => ('بررسی شبکه', Icons.more_horiz_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ModeHint extends StatelessWidget {
  const _ModeHint({
    super.key,
    required this.mode,
    required this.onIranWeb,
    required this.onOffline,
  });

  final NetworkMode? mode;
  final VoidCallback onIranWeb;
  final VoidCallback onOffline;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      NetworkMode.internalOnly => TextButton.icon(
          onPressed: onIranWeb,
          icon: const Icon(Icons.language_rounded, size: 17),
          label: const Text('جستجو در ایران وب'),
        ),
      NetworkMode.offline => TextButton.icon(
          onPressed: onOffline,
          icon: const Icon(Icons.offline_pin_outlined, size: 17),
          label: const Text('صفحات ذخیره‌شده'),
        ),
      _ => const SizedBox(height: 36),
    };
  }
}

class _TabsButton extends StatelessWidget {
  const _TabsButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow.withValues(alpha: .88),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.crop_square_rounded, size: 18),
              if (count > 0) ...[
                const SizedBox(width: 7),
                Text('$count'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
