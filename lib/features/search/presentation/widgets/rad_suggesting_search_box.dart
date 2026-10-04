import 'package:flutter/material.dart';

import '../../data/rad_smart_search_service.dart';

class RadSuggestingSearchBox extends StatefulWidget {
  const RadSuggestingSearchBox({
    super.key,
    required this.hint,
    required this.onSubmitted,
  });

  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  State<RadSuggestingSearchBox> createState() => _RadSuggestingSearchBoxState();
}

class _RadSuggestingSearchBoxState extends State<RadSuggestingSearchBox> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final RadSmartSearchService _service;
  List<String> _suggestions = const [];
  bool _focused = false;
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _service = RadSmartSearchService();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) _loadSuggestions(_controller.text);
  }

  Future<void> _loadSuggestions(String value) async {
    final generation = ++_generation;
    final clean = value.trim();
    if (clean.isEmpty) {
      final recent = await _service.recentSearches();
      if (!mounted || generation != _generation) return;
      setState(() {
        _suggestions = recent.take(6).toList(growable: false);
        _loading = false;
      });
      return;
    }
    if (clean.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    setState(() => _loading = true);
    final suggestions = await _service.suggestions(clean);
    if (!mounted || generation != _generation) return;
    setState(() {
      _suggestions = suggestions.take(6).toList(growable: false);
      _loading = false;
    });
  }

  void _submit(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    _focusNode.unfocus();
    widget.onSubmitted(clean);
  }

  void _choose(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _submit(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
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
            enableSuggestions: true,
            onChanged: _loadSuggestions,
            onSubmitted: _submit,
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
                  onPressed: () => _submit(_controller.text),
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
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: _focused && (_suggestions.isNotEmpty || _loading)
              ? Container(
                  key: const ValueKey('suggestions'),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow.withValues(alpha: .98),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: .4)),
                  ),
                  child: _loading && _suggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _suggestions
                              .map((item) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.search_rounded, size: 18),
                                    title: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl),
                                    trailing: const Icon(Icons.north_west_rounded, size: 16),
                                    onTap: () => _choose(item),
                                  ))
                              .toList(growable: false),
                        ),
                )
              : const SizedBox.shrink(key: ValueKey('no-suggestions')),
        ),
      ],
    );
  }
}
