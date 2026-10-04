class BrowserTab {
  const BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    this.faviconUrl,
    this.groupId,
    this.isLoading = false,
    this.progress = 0,
  });

  final String id;
  final Uri url;
  final String title;
  final Uri? faviconUrl;
  final String? groupId;
  final bool isLoading;
  final double progress;

  BrowserTab copyWith({
    Uri? url,
    String? title,
    Uri? faviconUrl,
    String? groupId,
    bool? isLoading,
    double? progress,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      groupId: groupId ?? this.groupId,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
    );
  }

  BrowserTab withGroup(String? value) {
    return BrowserTab(
      id: id,
      url: url,
      title: title,
      faviconUrl: faviconUrl,
      groupId: value,
      isLoading: isLoading,
      progress: progress,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'url': url.toString(),
        'title': title,
        'faviconUrl': faviconUrl?.toString(),
        'groupId': groupId,
      };

  factory BrowserTab.fromJson(Map<String, Object?> json) {
    final url = Uri.parse(json['url']! as String);
    final favicon = json['faviconUrl'] as String?;
    return BrowserTab(
      id: json['id']! as String,
      url: url,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title']! as String
          : url.host,
      faviconUrl: favicon == null || favicon.isEmpty ? null : Uri.tryParse(favicon),
      groupId: json['groupId'] as String?,
      isLoading: false,
      progress: 1,
    );
  }
}
