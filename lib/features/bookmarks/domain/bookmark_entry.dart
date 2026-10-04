class BookmarkEntry {
  const BookmarkEntry({
    required this.url,
    required this.title,
    required this.createdAt,
  });

  final Uri url;
  final String title;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'url': url.toString(),
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BookmarkEntry.fromJson(Map<String, Object?> json) {
    final url = Uri.parse(json['url']! as String);
    return BookmarkEntry(
      url: url,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title']! as String
          : url.host,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}
