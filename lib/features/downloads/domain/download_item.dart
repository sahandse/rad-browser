enum DownloadStatus { queued, downloading, completed, failed }

class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.url,
    required this.fileName,
    required this.createdAt,
    required this.status,
    this.progress = 0,
    this.savedLocation,
    this.errorMessage,
  });

  final String id;
  final Uri url;
  final String fileName;
  final DateTime createdAt;
  final DownloadStatus status;
  final double progress;
  final String? savedLocation;
  final String? errorMessage;

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? savedLocation,
    String? errorMessage,
  }) {
    return DownloadItem(
      id: id,
      url: url,
      fileName: fileName,
      createdAt: createdAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      savedLocation: savedLocation ?? this.savedLocation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'url': url.toString(),
        'fileName': fileName,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'progress': progress,
        'savedLocation': savedLocation,
        'errorMessage': errorMessage,
      };

  factory DownloadItem.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String? ?? DownloadStatus.completed.name;
    return DownloadItem(
      id: json['id']! as String,
      url: Uri.parse(json['url']! as String),
      fileName: json['fileName']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      status: DownloadStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => DownloadStatus.failed,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      savedLocation: json['savedLocation'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
