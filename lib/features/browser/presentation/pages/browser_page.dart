import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/url_utils.dart';
import '../../../bookmarks/presentation/controllers/bookmarks_controller.dart';
import '../../../bookmarks/presentation/pages/bookmarks_page.dart';
import '../../../downloads/presentation/controllers/downloads_controller.dart';
import '../../../downloads/presentation/pages/downloads_page.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../network/domain/network_mode.dart';
import '../../../network/presentation/network_providers.dart';
import '../../../offline/presentation/controllers/offline_pages_controller.dart';
import '../../../offline/presentation/pages/offline_pages_page.dart';
import '../../../privacy/domain/tracker_blocker.dart';
import '../../../reader/presentation/pages/reader_page.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/pages/settings_page.dart';
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
  late final TextEditingController _findController;
  late final FindInteractionController _findInteractionController;
  late Uri _currentUri;
  late final String _tabId;
  InAppWebViewController? _webViewController;
  PrintJobController? _printJobController;
  double _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isLoading = true;
  bool _mainFrameFailed = false;
  bool _showFindBar = false;
  bool _desktopMode = false;
  String _currentTitle = '';
  String _findStatus = '';
  int _blockedTrackerNavigations = 0;

  @override
  void initState() {
    super.initState();
    _currentUri = _resolveInput(widget.initialInput);
    _addressController = TextEditingController(text: _currentUri.toString());
    _findController = TextEditingController();
    _findInteractionController = FindInteractionController(
      onFindResultReceived: (_, activeMatchOrdinal, numberOfMatches, isDoneCounting) {
        if (!mounted || !isDoneCounting) return;
        setState(() {
          _findStatus = numberOfMatches > 0
              ? '${activeMatchOrdinal + 1}/$numberOfMatches'
              : '۰ نتیجه';
        });
      },
    );
    _tabId = widget.existingTabId ??
        ref.read(browserTabsProvider.notifier).open(_currentUri);
  }

  Uri _resolveInput(String input) {
    final value = input.trim();
    final settings = ref.read(settingsProvider);
    if (UrlUtils.looksLikeUrl(value)) {
      final uri = UrlUtils.resolve(value);
      if (settings.httpsFirst && uri.scheme == 'http') {
        return uri.replace(scheme: 'https');
      }
      return uri;
    }
    return settings.searchEngine.searchUri(value);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _findController.dispose();
    _printJobController?.dispose();
    super.dispose();
  }

  List<ContentBlocker> _contentBlockers(AppSettings settings) {
    final blockers = <ContentBlocker>[];
    if (settings.httpsFirst) {
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(urlFilter: '^http://.*'),
          action: ContentBlockerAction(type: ContentBlockerActionType.MAKE_HTTPS),
        ),
      );
    }
    if (settings.trackingProtection == RadTrackingProtection.off) {
      return blockers;
    }
    final filters = <String>[
      '.*doubleclick\\.net/.*',
      '.*google-analytics\\.com/.*',
      '.*googletagmanager\\.com/.*',
      '.*googlesyndication\\.com/.*',
      '.*connect\\.facebook\\.net/.*',
      '.*scorecardresearch\\.com/.*',
      '.*hotjar\\.com/.*',
      '.*clarity\\.ms/.*',
      '.*segment\\.(com|io)/.*',
      '.*mixpanel\\.com/.*',
      '.*amplitude\\.com/.*',
    ];
    if (settings.trackingProtection == RadTrackingProtection.strict) {
      filters.addAll([
        '.*adservice\\.google\\.com/.*',
        '.*adsrvr\\.org/.*',
        '.*criteo\\.(com|net)/.*',
        '.*taboola\\.com/.*',
        '.*outbrain\\.com/.*',
        '.*quantserve\\.com/.*',
        '.*demdex\\.net/.*',
        '.*branch\\.io/.*',
      ]);
    }
    for (final filter in filters) {
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(urlFilter: filter),
          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
        ),
      );
    }
    return blockers;
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
    final uri = _resolveInput(value);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentUri = uri;
      _addressController.text = uri.toString();
      _isLoading = true;
      _mainFrameFailed = false;
      _currentTitle = '';
      _blockedTrackerNavigations = 0;
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

  void _openDownloads() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DownloadsPage()),
    );
  }

  void _openOfflinePages() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OfflinePagesPage()),
    );
  }

  Future<String?> _extractReadableText() async {
    final controller = _webViewController;
    if (controller == null || _mainFrameFailed || _isLoading) return null;
    final raw = await controller.evaluateJavascript(
      source: '''
        (() => {
          const root = document.querySelector('article, main, [role="main"]') || document.body;
          return root ? root.innerText : '';
        })();
      ''',
    );
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return null;
    return value;
  }

  Future<void> _saveOfflinePage() async {
    final content = await _extractReadableText();
    if (content == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('محتوایی برای ذخیره پیدا نشد')),
      );
      return;
    }
    final title = _currentTitle.isEmpty ? _currentUri.host : _currentTitle;
    await ref.read(offlinePagesProvider.notifier).save(
          url: _currentUri,
          title: title,
          content: content,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('صفحه برای مطالعه آفلاین ذخیره شد'),
        action: SnackBarAction(label: 'مشاهده', onPressed: _openOfflinePages),
      ),
    );
  }

  Future<void> _openReader() async {
    final content = await _extractReadableText();
    if (content == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('متن قابل مطالعه‌ای در این صفحه پیدا نشد')),
        );
      }
      return;
    }
    final title = _currentTitle.isEmpty ? _currentUri.host : _currentTitle;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderPage(title: title, url: _currentUri, content: content),
      ),
    );
  }

  Future<void> _handleDownload(DownloadStartRequest request) async {
    final uri = Uri.tryParse(request.url.toString());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    await ref.read(downloadsProvider.notifier).start(
          uri,
          suggestedFileName: request.suggestedFilename,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('دانلود شروع شد'),
        action: SnackBarAction(label: 'دانلودها', onPressed: _openDownloads),
      ),
    );
  }

  Future<void> _sharePage() async {
    final title = _currentTitle.isEmpty ? _currentUri.host : _currentTitle;
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        text: '$title\n${_currentUri.toString()}',
      ),
    );
  }

  Future<void> _printPage() async {
    final controller = _webViewController;
    if (controller == null) return;
    if (kIsWeb) {
      await controller.evaluateJavascript(source: 'window.print();');
      return;
    }
    _printJobController?.dispose();
    _printJobController = await controller.printCurrentPage(
      settings: PrintJobSettings(
        handledByClient: true,
        jobName: _currentTitle.isEmpty ? _currentUri.host : _currentTitle,
      ),
    );
  }

  Future<void> _toggleDesktopMode() async {
    _desktopMode = !_desktopMode;
    await _webViewController?.setSettings(
      settings: InAppWebViewSettings(
        preferredContentMode: _desktopMode
            ? UserPreferredContentMode.DESKTOP
            : UserPreferredContentMode.MOBILE,
      ),
    );
    await _webViewController?.reload();
    if (mounted) setState(() {});
  }

  Future<void> _showFind() async {
    setState(() => _showFindBar = true);
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _closeFind() async {
    await _findInteractionController.clearMatches();
    _findController.clear();
    if (mounted) {
      setState(() {
        _showFindBar = false;
        _findStatus = '';
      });
    }
  }

  Future<void> _showSiteInfo(BuildContext context) async {
    final settings = ref.read(settingsProvider);
    var cookieCount = 0;
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(_currentUri.toString()),
      );
      cookieCount = cookies.length;
    } on Object {
      cookieCount = 0;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      _currentUri.scheme == 'https'
                          ? Icons.lock_rounded
                          : Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUri.host,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          _currentUri.scheme == 'https'
                              ? 'اتصال HTTPS'
                              : 'اتصال HTTP — رمزگذاری نشده',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _InfoRow(label: 'دامنه ایران', value: UrlUtils.isIrDomain(_currentUri) ? 'بله' : 'خیر'),
              _InfoRow(label: 'کوکی‌های این سایت', value: '$cookieCount'),
              _InfoRow(label: 'محافظت رهگیری', value: settings.trackingProtection.title),
              _InfoRow(label: 'هدایت رهگیر مسدودشده', value: '$_blockedTrackerNavigations'),
              _InfoRow(label: 'HTTPS-first', value: settings.httpsFirst ? 'فعال' : 'خاموش'),
              _InfoRow(label: 'حالت دسکتاپ', value: _desktopMode ? 'فعال' : 'خاموش'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final isIr = UrlUtils.isIrDomain(_currentUri);
    final isSecure = _currentUri.scheme == 'https';
    final tabCount = ref.watch(browserTabsProvider).length;
    final networkMode = ref.watch(networkModeProvider).valueOrNull;
    final blocker = TrackerBlocker(settings.trackingProtection);

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
                          prefixIcon: IconButton(
                            tooltip: 'اطلاعات سایت',
                            onPressed: () => _showSiteInfo(context),
                            icon: Icon(
                              isIr
                                  ? Icons.public_rounded
                                  : isSecure
                                      ? Icons.lock_rounded
                                      : Icons.warning_amber_rounded,
                              size: 18,
                              color: isIr ? scheme.primary : scheme.onSurfaceVariant,
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
                              _isLoading ? Icons.close_rounded : Icons.refresh_rounded,
                              size: 20,
                            ),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'منو',
                    onPressed: () => _showBrowserMenu(context),
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
            ),
            if (_showFindBar)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _findController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'پیدا کردن در صفحه',
                          border: InputBorder.none,
                          suffixText: _findStatus,
                        ),
                        onSubmitted: (value) async {
                          if (value.trim().isEmpty) {
                            await _findInteractionController.clearMatches();
                            return;
                          }
                          await _findInteractionController.findAll(find: value.trim());
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'قبلی',
                      onPressed: () => _findInteractionController.findNext(forward: false),
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                    IconButton(
                      tooltip: 'بعدی',
                      onPressed: () => _findInteractionController.findNext(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    IconButton(
                      tooltip: 'بستن',
                      onPressed: _closeFind,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: _progress >= 1 ? 0 : 2,
              alignment: Alignment.centerLeft,
              child: LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(_currentUri.toString())),
                      findInteractionController: _findInteractionController,
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        transparentBackground: false,
                        supportZoom: true,
                        builtInZoomControls: false,
                        displayZoomControls: false,
                        useShouldOverrideUrlLoading: true,
                        useOnDownloadStart: true,
                        mediaPlaybackRequiresUserGesture: settings.dataSaver,
                        allowsBackForwardNavigationGestures: true,
                        supportMultipleWindows: false,
                        javaScriptCanOpenWindowsAutomatically: !settings.blockPopups,
                        preferredContentMode: _desktopMode
                            ? UserPreferredContentMode.DESKTOP
                            : UserPreferredContentMode.MOBILE,
                        contentBlockers: _contentBlockers(settings),
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      shouldOverrideUrlLoading: (controller, action) async {
                        final raw = action.request.url?.toString();
                        final uri = raw == null ? null : Uri.tryParse(raw);
                        if (uri != null && blocker.shouldBlock(uri, _currentUri)) {
                          if (mounted) {
                            setState(() => _blockedTrackerNavigations++);
                          }
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (uri != null && settings.httpsFirst && uri.scheme == 'http') {
                          await controller.loadUrl(
                            urlRequest: URLRequest(
                              url: WebUri(uri.replace(scheme: 'https').toString()),
                            ),
                          );
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                      onDownloadStarting: (controller, request) async {
                        await _handleDownload(request);
                        return null;
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
                          final title = _currentTitle.isEmpty ? uri.host : _currentTitle;
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
                        onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
        minimum: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: .5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    tooltip: 'عقب',
                    onPressed: _canGoBack ? _goBack : () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  IconButton(
                    tooltip: 'جلو',
                    onPressed: _canGoForward ? _goForward : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  IconButton(
                    tooltip: 'خانه',
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
        ),
      ),
    );
  }

  Future<void> _showBrowserMenu(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final isBookmarked = ref.read(bookmarksProvider.notifier).contains(_currentUri);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .78),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_rounded),
                title: const Text('حالت مطالعه'),
                enabled: !_isLoading && !_mainFrameFailed,
                onTap: !_isLoading && !_mainFrameFailed
                    ? () async {
                        Navigator.pop(sheetContext);
                        await _openReader();
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.find_in_page_outlined),
                title: const Text('پیدا کردن در صفحه'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _showFind();
                },
              ),
              ListTile(
                leading: Icon(_desktopMode ? Icons.phone_android_rounded : Icons.desktop_windows_rounded),
                title: Text(_desktopMode ? 'نمایش موبایل' : 'سایت دسکتاپ'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _toggleDesktopMode();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('اشتراک‌گذاری'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _sharePage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('چاپ / ذخیره PDF'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _printPage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('اطلاعات و امنیت سایت'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSiteInfo(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(isBookmarked ? Icons.star_rounded : Icons.star_border_rounded),
                title: Text(isBookmarked ? 'حذف از نشانک‌ها' : 'افزودن به نشانک‌ها'),
                onTap: () async {
                  final title = _currentTitle.isEmpty ? _currentUri.host : _currentTitle;
                  await ref.read(bookmarksProvider.notifier).toggle(url: _currentUri, title: title);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.offline_pin_outlined),
                title: const Text('ذخیره برای مطالعه آفلاین'),
                enabled: !_isLoading && !_mainFrameFailed,
                onTap: !_isLoading && !_mainFrameFailed
                    ? () async {
                        Navigator.pop(sheetContext);
                        await _saveOfflinePage();
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('صفحات آفلاین'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openOfflinePages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('نشانک‌ها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BookmarksPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('تاریخچه'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HistoryPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('دانلودها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openDownloads();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('تنظیمات'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
                },
              ),
              const Divider(),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, textDirection: TextDirection.rtl)),
          Text(
            value,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
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
          'صفحات ذخیره‌شده، نشانک‌ها و ایران وب از صفحه اصلی همچنان در دسترس‌اند.'
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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
                    OutlinedButton(onPressed: onHome, child: const Text('خانه')),
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
