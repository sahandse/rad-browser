import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/presentation/controllers/bookmarks_controller.dart';
import '../../history/presentation/controllers/history_controller.dart';
import '../../iran_directory/data/iran_directory_repository.dart';
import '../../iran_directory/domain/iran_site.dart';
import '../domain/search_suggestion.dart';

final iranDirectoryProvider = FutureProvider<List<IranSite>>((ref) async {
  return IranDirectoryRepository().loadBundled();
});

final searchSuggestionsProvider =
    Provider.family<List<SearchSuggestion>, String>((ref, query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final suggestions = <SearchSuggestion>[];

  for (final item in ref.watch(bookmarksProvider)) {
    final haystack = '${item.title} ${item.url}'.toLowerCase();
    if (haystack.contains(q)) {
      suggestions.add(
        SearchSuggestion(
          title: item.title,
          url: item.url,
          source: SearchSuggestionSource.bookmark,
        ),
      );
    }
  }

  for (final item in ref.watch(historyProvider)) {
    final haystack = '${item.title} ${item.url}'.toLowerCase();
    if (haystack.contains(q) &&
        !suggestions.any((suggestion) => suggestion.url == item.url)) {
      suggestions.add(
        SearchSuggestion(
          title: item.title,
          url: item.url,
          source: SearchSuggestionSource.history,
        ),
      );
    }
  }

  final directory = ref.watch(iranDirectoryProvider).valueOrNull ?? const <IranSite>[];
  for (final site in directory) {
    final haystack = [
      site.name,
      site.url.host,
      site.description,
      ...site.keywords,
      ...site.features,
    ].join(' ').toLowerCase();
    if (haystack.contains(q) &&
        !suggestions.any((suggestion) => suggestion.url == site.url)) {
      suggestions.add(
        SearchSuggestion(
          title: site.name,
          url: site.url,
          source: SearchSuggestionSource.iranDirectory,
        ),
      );
    }
  }

  return suggestions.take(8).toList(growable: false);
});
