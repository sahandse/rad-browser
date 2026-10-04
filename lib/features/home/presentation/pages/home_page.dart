import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/url_utils.dart';
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
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _openBrowser(
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
    if (!UrlUtils.looksLikeUrl(value) && mode == NetworkMode.internalOnly) {
      _openIranDirectory(context, initialQuery: value);
      return;
    }

    final target = UrlUtils.looksLikeUrl(value)
        ? value
        : ref.read(settingsProvider).searchEngine.searchUri(value).toString();

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BrowserPage(initialInput: target)),
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
        if (query.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: query));
        }
        if (!context.mounted) return true;
        _openDirect(context, 'https://zarebin.ir/');
        if (query.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عبارت کپی شد؛ در ذره‌بین جای‌گذاری کنید')),
          );
        }
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

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 12,
              child: IconButton(
                tooltip: 'منو',
                onPressed: () => _showHomeMenu(context),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ),
            Positioned(
              top: 14,
              right: 16,
              child: _MinimalNetworkStatus(mode: mode),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 84, 24, 110),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _RadLogo(),
                      const SizedBox(height: 38),
                      _GoogleLikeSearchBox(
                        hint: mode == NetworkMode.internalOnly
                            ? 'جستجو در وب داخلی ایران'
                            : mode == NetworkMode.offline
                                ? 'جستجو یا نشانی ذخیره‌شده'
                                : 'جستجو یا وارد کردن نشانی وب',
                        onSubmitted: (value) => _openBrowser(context, ref, value),
                      ),
                      const SizedBox(height: 14),
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
              leading: const Icon(Icons.travel_explore_rounded),
              title: const Text('ذره‌بین'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openDirect(context, 'https://zarebin.ir/');
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

class _RadLogo extends StatelessWidget {
  const _RadLogo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: .72),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: .18),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'R',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 58,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -3,
                ),
              ),
              Positioned(
                right: 20,
                bottom: 18,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'راد',
          textDirection: TextDirection.rtl,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
      ],
    );
  }
}

class _GoogleLikeSearchBox extends StatefulWidget {
  const _GoogleLikeSearchBox({
    required this.hint,
    required this.onSubmitted,
  });

  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  State<_GoogleLikeSearchBox> createState() => _GoogleLikeSearchBoxState();
}

class _GoogleLikeSearchBoxState extends State<_GoogleLikeSearchBox> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
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
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .62),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 7),
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
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 23),
          suffixIcon: IconButton(
            tooltip: 'برو',
            onPressed: () => widget.onSubmitted(_controller.text),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
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
      NetworkMode.fullInternet => ('اینترنت', Icons.circle),
      NetworkMode.internalOnly => ('شبکه داخلی', Icons.public_rounded),
      NetworkMode.offline => ('آفلاین', Icons.cloud_off_rounded),
      null => ('بررسی شبکه', Icons.more_horiz_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: scheme.primary),
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
          label: const Text('اینترنت بین‌الملل در دسترس نیست — جستجو در ایران وب'),
        ),
      NetworkMode.offline => TextButton.icon(
          onPressed: onOffline,
          icon: const Icon(Icons.offline_pin_outlined, size: 17),
          label: const Text('آفلاین — باز کردن صفحات ذخیره‌شده'),
        ),
      _ => const SizedBox(height: 40),
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
      color: scheme.surfaceContainerLow.withValues(alpha: .94),
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
