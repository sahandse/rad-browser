class IranSite {
  const IranSite({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
    required this.keywords,
    required this.verified,
    required this.internalNetwork,
    required this.priority,
  });

  final String id;
  final String name;
  final Uri url;
  final String category;
  final List<String> keywords;
  final bool verified;
  final bool internalNetwork;
  final int priority;

  factory IranSite.fromJson(Map<String, Object?> json) {
    return IranSite(
      id: json['id']! as String,
      name: json['name']! as String,
      url: Uri.parse(json['url']! as String),
      category: json['category']! as String,
      keywords: (json['keywords'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      verified: json['verified'] as bool? ?? false,
      internalNetwork: json['internalNetwork'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
    );
  }
}
