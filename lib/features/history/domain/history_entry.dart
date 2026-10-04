class HistoryEntry {
  const HistoryEntry({
    required this.url,
    required this.title,
    required this.visitedAt,
  });

  final Uri url;
  final String title;
  final DateTime visitedAt;

  Map<String, Object?> toJson() => {
        'url': url.toString(),
        'title': title,
        'visitedAt': visitedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, Object?> json) {
    return HistoryEntry(
      url: Uri.parse(json['url']! as String),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title']! as String
          : Uri.parse(json['url']! as String).host,
      visitedAt: DateTime.parse(json['visitedAt']! as String),
    );
  }
}
