import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../search/domain/search_suggestion.dart';
import '../../../search/presentation/search_providers.dart';

class RadSearchBar extends ConsumerStatefulWidget {
  const RadSearchBar({super.key, this.onSubmitted});

  final ValueChanged<String>? onSubmitted;

  @override
  ConsumerState<RadSearchBar> createState() => _RadSearchBarState();
}

class _RadSearchBarState extends ConsumerState<RadSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    _focusNode.unfocus();
    widget.onSubmitted?.call(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(searchSuggestionsProvider(_query));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showSuggestions = _focusNode.hasFocus && suggestions.isNotEmpty;

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.go,
            onSubmitted: _submit,
            onChanged: (value) => setState(() => _query = value),
            textDirection: TextDirection.rtl,
            cursorColor: scheme.primary,
            decoration: InputDecoration(
              hintText: 'جستجو یا وارد کردن آدرس',
              hintTextDirection: TextDirection.rtl,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'پاک کردن',
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                        _focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: showSuggestions
              ? Container(
                  key: const ValueKey('suggestions'),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: .45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: suggestions.map((suggestion) {
                      return ListTile(
                        dense: true,
                        leading: Icon(_iconFor(suggestion.source), size: 20),
                        title: Text(
                          suggestion.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          suggestion.url.host,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _controller.text = suggestion.url.toString();
                          setState(() => _query = _controller.text);
                          _submit(_controller.text);
                        },
                      );
                    }).toList(growable: false),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-suggestions')),
        ),
      ],
    );
  }

  IconData _iconFor(SearchSuggestionSource source) => switch (source) {
        SearchSuggestionSource.bookmark => Icons.star_rounded,
        SearchSuggestionSource.history => Icons.history_rounded,
        SearchSuggestionSource.iranDirectory => Icons.language_rounded,
      };
}
