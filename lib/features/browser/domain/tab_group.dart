class TabGroup {
  const TabGroup({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  TabGroup copyWith({String? title}) {
    return TabGroup(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TabGroup.fromJson(Map<String, Object?> json) {
    return TabGroup(
      id: json['id']! as String,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title']! as String
          : 'گروه',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
