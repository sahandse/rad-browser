import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/rad_theme.dart';
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
  void dispose() {
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
    final scheme = Theme.of(context).colorScheme;
    final showSuggestions = _focusNode.hasFocus && suggestions.isNotEmpty;

    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.go,
          onSubmitted: _submit,
          onChanged: (value) => setState(() => _query = value),
          onTap: () => setState(() {}),
          textDirection: TextDirection.rtl,
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
          style: const TextStyle(fontSize: 16, color: RadColors.text),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: showSuggestions
              ? Container(
                  key: const ValueKey('suggestions'),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: .45),
                    ),
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
