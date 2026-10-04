import 'package:flutter/material.dart';

import '../../../../core/utils/url_utils.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key, required this.initialInput});

  final String initialInput;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final TextEditingController _addressController;
  late Uri _currentUri;

  @override
  void initState() {
    super.initState();
    _currentUri = UrlUtils.resolve(widget.initialInput);
    _addressController = TextEditingController(text: _currentUri.toString());
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _navigate(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      _currentUri = UrlUtils.resolve(value);
      _addressController.text = _currentUri.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIr = UrlUtils.isIrDomain(_currentUri);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Container(
          height: 46,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _addressController,
            textInputAction: TextInputAction.go,
            onSubmitted: _navigate,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              isDense: true,
              fillColor: Colors.transparent,
              prefixIcon: Icon(
                isIr ? Icons.flag_rounded : Icons.lock_outline_rounded,
                size: 18,
              ),
              suffixIcon: IconButton(
                tooltip: 'تازه‌سازی',
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'منو',
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 46, color: theme.colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                'Browser Engine',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _currentUri.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isIr ? 'دامنه داخلی شناسایی شد' : 'آماده اتصال به WebView',
                textDirection: TextDirection.rtl,
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_rounded)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_rounded),
              ),
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
