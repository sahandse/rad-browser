class OfflinePage {
  const OfflinePage({
    required this.url,
    required this.title,
    required this.content,
    required this.savedAt,
  });

  final Uri url;
  final String title;
  final String content;
  final DateTime savedAt;

  Map<String, Object?> toJson() => {
        'url': url.toString(),
        'title': title,
        'content': content,
        'savedAt': savedAt.toIso8601String(),
      };

  factory OfflinePage.fromJson(Map<String, Object?> json) {
    return OfflinePage(
      url: Uri.parse(json['url']! as String),
      title: json['title']! as String,
      content: json['content']! as String,
      savedAt: DateTime.parse(json['savedAt']! as String),
    );
  }
}
