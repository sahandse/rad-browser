import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/url_utils.dart';
import '../../../bookmarks/presentation/controllers/bookmarks_controller.dart';
import '../../../bookmarks/presentation/pages/bookmarks_page.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../network/domain/network_mode.dart';
import '../../../network/presentation/network_providers.dart';
import '../controllers/browser_tabs_controller.dart';
import 'tabs_page.dart';

class BrowserPage extends ConsumerStatefulWidget {
  const BrowserPage({
    super.key,
    required this.initialInput,
    this.existingTabId,
  });

  final String initialInput;
  final String? existingTabId;

  @override
  ConsumerState<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends ConsumerState<BrowserPage> {
  late final TextEditingController _addressController;
  late Uri _currentUri;
  late final String _tabId;
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isLoading = true;
  bool _mainFrameFailed = false;
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _currentUri = UrlUtils.resolve(widget.initialInput);
    _addressController = TextEditingController(text: _currentUri.toString());
    _tabId = widget.existingTabId ??
        ref.read(browserTabsProvider.notifier).open(_currentUri);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _syncNavigationState() async {
    final controller = _webViewController;
    if (controller == null) return;
    final back = await controller.canGoBack();
    final forward = await controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  Future<void> _navigate(String value) async {
    if (value.trim().isEmpty) return;
    final uri = UrlUtils.resolve(value);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentUri = uri;
      _addressController.text = uri.toString();
      _isLoading = true;
      _mainFrameFailed = false;
      _currentTitle = '';
    });
    ref.read(browserTabsProvider.notifier).update(
          _tabId,
          url: uri,
          isLoading: true,
          progress: 0,
        );
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(uri.toString())),
    );
  }

  Future<void> _goBack() async {
    final controller = _webViewController;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    if (mounted) Navigator.maybePop(context);
  }

  Future<void> _goForward() async {
    final controller = _webViewController;
    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  void _openTabs() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TabsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isIr = UrlUtils.isIrDomain(_currentUri);
    final isSecure = _currentUri.scheme == 'https';
    final tabCount = ref.watch(browserTabsProvider).length;
    final networkMode = ref.watch(networkModeProvider).valueOrNull;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: .45),
                        ),
                      ),
                      child: TextField(
                        controller: _addressController,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enableSuggestions: false,
                        onSubmitted: _navigate,
                        onTap: () {
                          _addressController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _addressController.text.length,
                          );
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          prefixIcon: Tooltip(
                            message: isIr
                                ? 'دامنه ایران'
                                : isSecure
                                    ? 'اتصال امن'
                                    : 'اطلاعات سایت',
                            child: Icon(
                              isIr
                                  ? Icons.public_rounded
                                  : isSecure
                                      ? Icons.lock_rounded
                                      : Icons.info_outline_rounded,
                              size: 18,
                              color: isIr
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _isLoading ? 'توقف' : 'تازه‌سازی',
                            onPressed: () async {
                              if (_isLoading) {
                                await _webViewController?.stopLoading();
                              } else {
                                setState(() => _mainFrameFailed = false);
                                await _webViewController?.reload();
                              }
                            },
                            icon: Icon(
                              _isLoading
                                  ? Icons.close_rounded
                                  : Icons.refresh_rounded,
                              size: 20,
                            ),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'منو',
                    onPressed: () => _showBrowserMenu(context),
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: _progress >= 1 ? 0 : 2,
              alignment: Alignment.centerLeft,
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(_currentUri.toString()),
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        transparentBackground: false,
                        supportZoom: true,
                        builtInZoomControls: false,
                        displayZoomControls: false,
                        useShouldOverrideUrlLoading: true,
                        mediaPlaybackRequiresUserGesture: true,
                        allowsBackForwardNavigationGestures: true,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      shouldOverrideUrlLoading: (controller, action) async {
                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStart: (controller, url) {
                        if (url == null) return;
                        final uri = Uri.tryParse(url.toString());
                        if (uri == null || !mounted) return;
                        setState(() {
                          _currentUri = uri;
                          _addressController.text = uri.toString();
                          _isLoading = true;
                          _mainFrameFailed = false;
                          _currentTitle = '';
                        });
                        ref.read(browserTabsProvider.notifier).update(
                              _tabId,
                              url: uri,
                              isLoading: true,
                            );
                        _syncNavigationState();
                      },
                      onProgressChanged: (controller, progress) {
                        if (!mounted) return;
                        final value = progress / 100;
                        setState(() => _progress = value);
                        ref.read(browserTabsProvider.notifier).update(
                              _tabId,
                              progress: value,
                            );
                      },
                      onTitleChanged: (controller, title) {
                        if (title == null || title.trim().isEmpty) return;
                        _currentTitle = title.trim();
                        ref.read(browserTabsProvider.notifier).update(
                              _tabId,
                              title: _currentTitle,
                            );
                      },
                      onLoadStop: (controller, url) async {
                        if (!mounted) return;
                        Uri? uri;
                        if (url != null) uri = Uri.tryParse(url.toString());
                        if (uri != null) {
                          _currentUri = uri;
                          _addressController.text = uri.toString();
                        }
                        setState(() {
                          _isLoading = false;
                          _progress = 1;
                          _mainFrameFailed = false;
                        });
                        ref.read(browserTabsProvider.notifier).update(
                              _tabId,
                              url: uri,
                              isLoading: false,
                              progress: 1,
                            );
                        if (uri != null) {
                          final title =
                              _currentTitle.isEmpty ? uri.host : _currentTitle;
                          await ref.read(historyProvider.notifier).record(
                                url: uri,
                                title: title,
                              );
                        }
                        await _syncNavigationState();
                      },
                      onReceivedError: (controller, request, error) {
                        if (request.isForMainFrame != true || !mounted) return;
                        setState(() {
                          _isLoading = false;
                          _progress = 1;
                          _mainFrameFailed = true;
                        });
                        ref.read(browserTabsProvider.notifier).update(
                              _tabId,
                              isLoading: false,
                              progress: 1,
                            );
                      },
                    ),
                  ),
                  if (_mainFrameFailed)
                    Positioned.fill(
                      child: _BrowserErrorView(
                        uri: _currentUri,
                        mode: networkMode,
                        onRetry: () async {
                          setState(() => _mainFrameFailed = false);
                          await _webViewController?.reload();
                        },
                        onHome: () => Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: .5),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: 'عقب',
                onPressed: _canGoBack
                    ? _goBack
                    : () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              IconButton(
                tooltip: 'جلو',
                onPressed: _canGoForward ? _goForward : null,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              IconButton(
                tooltip: 'خانه',
                onPressed: () => Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                ),
                icon: const Icon(Icons.home_outlined),
              ),
              Badge(
                label: Text('$tabCount'),
                child: IconButton(
                  tooltip: 'تب‌ها',
                  onPressed: _openTabs,
                  icon: const Icon(Icons.crop_square_rounded),
                ),
              ),
              IconButton(
                tooltip: 'منو',
                onPressed: () => _showBrowserMenu(context),
                icon: const Icon(Icons.menu_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBrowserMenu(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final isBookmarked =
        ref.read(bookmarksProvider.notifier).contains(_currentUri);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                ),
                title: Text(
                  isBookmarked ? 'حذف از نشانک‌ها' : 'افزودن به نشانک‌ها',
                ),
                onTap: () async {
                  final title =
                      _currentTitle.isEmpty ? _currentUri.host : _currentTitle;
                  await ref.read(bookmarksProvider.notifier).toggle(
                        url: _currentUri,
                        title: title,
                      );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('نشانک‌ها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BookmarksPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('تاریخچه'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HistoryPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('تب جدید'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('تازه‌سازی'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  setState(() => _mainFrameFailed = false);
                  await _webViewController?.reload();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('بستن این تب'),
                onTap: () {
                  ref.read(browserTabsProvider.notifier).close(_tabId);
                  Navigator.pop(sheetContext);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowserErrorView extends StatelessWidget {
  const _BrowserErrorView({
    required this.uri,
    required this.mode,
    required this.onRetry,
    required this.onHome,
  });

  final Uri uri;
  final NetworkMode? mode;
  final Future<void> Function() onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isIr = UrlUtils.isIrDomain(uri);

    final (icon, title, message) = switch (mode) {
      NetworkMode.offline => (
          Icons.cloud_off_rounded,
          'اتصال شبکه وجود ندارد',
          'پس از برقراری اتصال دوباره تلاش کنید.'
        ),
      NetworkMode.internalOnly when !isIr => (
          Icons.public_off_rounded,
          'اینترنت بین‌الملل در دسترس نیست',
          'شبکه داخلی فعال است. می‌توانید از صفحه اصلی در سایت‌های داخلی جستجو کنید.'
        ),
      NetworkMode.internalOnly => (
          Icons.wifi_tethering_error_rounded,
          'این سایت داخلی پاسخ نمی‌دهد',
          'شبکه داخلی فعال است، اما این سایت در حال حاضر قابل دسترس نیست.'
        ),
      _ => (
          Icons.error_outline_rounded,
          'سایت در دسترس نیست',
          'اتصال برقرار است، اما این سایت پاسخ نمی‌دهد.'
        ),
    };

    return ColoredBox(
      color: scheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: scheme.primary),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: onHome,
                      child: const Text('خانه'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('تلاش دوباره'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
