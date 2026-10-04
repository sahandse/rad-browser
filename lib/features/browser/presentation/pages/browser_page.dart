import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/url_utils.dart';
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
                  ref.read(browserTabsProvider.notifier).update(
                        _tabId,
                        title: title.trim(),
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
                  });
                  ref.read(browserTabsProvider.notifier).update(
                        _tabId,
                        url: uri,
                        isLoading: false,
                        progress: 1,
                      );
                  await _syncNavigationState();
                },
                onReceivedError: (controller, request, error) {
                  if (!request.isForMainFrame || !mounted) return;
                  setState(() {
                    _isLoading = false;
                    _progress = 1;
                  });
                  ref.read(browserTabsProvider.notifier).update(
                        _tabId,
                        isLoading: false,
                        progress: 1,
                      );
                },
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
