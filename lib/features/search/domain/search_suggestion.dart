enum SearchSuggestionSource { bookmark, history, iranDirectory }

class SearchSuggestion {
  const SearchSuggestion({
    required this.title,
    required this.url,
    required this.source,
  });

  final String title;
  final Uri url;
  final SearchSuggestionSource source;
}
