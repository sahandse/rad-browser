class BrowserTab {
  const BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    this.faviconUrl,
    this.isLoading = false,
    this.progress = 0,
  });

  final String id;
  final Uri url;
  final String title;
  final Uri? faviconUrl;
  final bool isLoading;
  final double progress;

  BrowserTab copyWith({
    Uri? url,
    String? title,
    Uri? faviconUrl,
    bool? isLoading,
    double? progress,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
    );
  }
}
