import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/url_utils.dart';
import '../../../privacy/domain/tracker_blocker.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

class PrivateBrowserPage extends ConsumerStatefulWidget {
  const PrivateBrowserPage({super.key, this.initialInput = 'https://zarebin.ir/'});

  final String initialInput;

  @override
  ConsumerState<PrivateBrowserPage> createState() => _PrivateBrowserPageState();
}

class _PrivateBrowserPageState extends ConsumerState<PrivateBrowserPage> {
  late final TextEditingController _addressController;
  InAppWebViewController? _controller;
  late Uri _currentUri;
  double _progress = 0;
  bool _loading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUri = _resolve(widget.initialInput);
    _addressController = TextEditingController(text: _currentUri.toString());
  }

  Uri _resolve(String input) {
    final value = input.trim();
    if (UrlUtils.looksLikeUrl(value)) {
      final uri = UrlUtils.resolve(value);
      final settings = ref.read(settingsProvider);
      if (settings.httpsFirst && uri.scheme == 'http') {
        return uri.replace(scheme: 'https');
      }
      return uri;
    }
    return ref.read(settingsProvider).searchEngine.searchUri(value);
  }

  Future<void> _navigate(String input) async {
    if (input.trim().isEmpty) return;
    final uri = _resolve(input);
    setState(() {
      _currentUri = uri;
      _addressController.text = uri.toString();
      _loading = true;
    });
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(uri.toString())),
    );
  }

  Future<void> _syncNavigation() async {
    final controller = _controller;
    if (controller == null) return;
    final back = await controller.canGoBack();
    final forward = await controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  Future<void> _applyDataSaver() async {
    if (!ref.read(settingsProvider).dataSaver) return;
    await _controller?.evaluateJavascript(
      source: '''
        (() => {
          const media = document.querySelectorAll('video, audio');
          media.forEach((node) => {
            try {
              node.autoplay = false;
              node.preload = 'none';
              node.removeAttribute('autoplay');
              node.pause();
            } catch (_) {}
          });
          const sources = document.querySelectorAll('source[media]');
          sources.forEach((node) => {
            try { node.setAttribute('data-rad-deferred', '1'); } catch (_) {}
          });
        })();
      ''',
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
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
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.inverseSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.visibility_off_rounded,
                      size: 19,
                      color: scheme.onInverseSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      textInputAction: TextInputAction.go,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: _navigate,
                      decoration: InputDecoration(
                        hintText: 'جستجو یا نشانی وب — خصوصی',
                        isDense: true,
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _loading ? 'توقف' : 'تازه‌سازی',
                          onPressed: () async {
                            if (_loading) {
                              await _controller?.stopLoading();
                            } else {
                              await _controller?.reload();
                            }
                          },
                          icon: Icon(
                            _loading ? Icons.close_rounded : Icons.refresh_rounded,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'بستن مرور خصوصی',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: _progress >= 1 ? 0 : 2,
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
                  incognito: true,
                  cacheEnabled: false,
                  thirdPartyCookiesEnabled: false,
                  supportMultipleWindows: false,
                  javaScriptCanOpenWindowsAutomatically: !settings.blockPopups,
                  mediaPlaybackRequiresUserGesture: settings.dataSaver,
                  useShouldOverrideUrlLoading: true,
                ),
                onWebViewCreated: (controller) => _controller = controller,
                shouldOverrideUrlLoading: (controller, action) async {
                  final raw = action.request.url?.toString();
                  final uri = raw == null ? null : Uri.tryParse(raw);
                  if (uri != null && blocker.shouldBlock(uri, _currentUri)) {
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
                onLoadStart: (controller, url) {
                  final uri = url == null ? null : Uri.tryParse(url.toString());
                  if (uri == null || !mounted) return;
                  setState(() {
                    _currentUri = uri;
                    _addressController.text = uri.toString();
                    _loading = true;
                  });
                  _syncNavigation();
                },
                onProgressChanged: (controller, progress) {
                  if (!mounted) return;
                  setState(() => _progress = progress / 100);
                },
                onLoadStop: (controller, url) async {
                  if (!mounted) return;
                  setState(() {
                    _loading = false;
                    _progress = 1;
                  });
                  await _applyDataSaver();
                  await _syncNavigation();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 6, 28, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: 'عقب',
                onPressed: _canGoBack ? () => _controller?.goBack() : null,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              IconButton(
                tooltip: 'جلو',
                onPressed: _canGoForward ? () => _controller?.goForward() : null,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              Tooltip(
                message: 'مرور خصوصی — تاریخچه ذخیره نمی‌شود',
                child: Icon(Icons.shield_rounded, color: scheme.primary),
              ),
              IconButton(
                tooltip: 'تازه‌سازی',
                onPressed: () => _controller?.reload(),
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'بستن',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
