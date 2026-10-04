import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/download_item.dart';

final downloadsProvider =
    StateNotifierProvider<DownloadsController, List<DownloadItem>>((ref) {
  final controller = DownloadsController();
  unawaited(controller.load());
  return controller;
});

class DownloadsController extends StateNotifier<List<DownloadItem>> {
  DownloadsController({Dio? dio})
      : _dio = dio ?? Dio(),
        super(const []);

  static const _storageKey = 'rad.downloads.v1';
  final Dio _dio;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final restored = <DownloadItem>[];
    for (final item in raw) {
      try {
        final json = jsonDecode(item) as Map<String, Object?>;
        final parsed = DownloadItem.fromJson(json);
        if (parsed.status == DownloadStatus.downloading ||
            parsed.status == DownloadStatus.queued) {
          restored.add(parsed.copyWith(
            status: DownloadStatus.failed,
            errorMessage: 'دانلود پیشین کامل نشده است.',
          ));
        } else {
          restored.add(parsed);
        }
      } on Object {
        // Ignore a corrupted record without affecting other downloads.
      }
    }
    restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (state.isEmpty) state = restored;
    _loaded = true;
  }

  Future<void> start(Uri url, {String? suggestedFileName}) async {
    await load();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final fileName = _resolveFileName(url, suggestedFileName);
    final item = DownloadItem(
      id: id,
      url: url,
      fileName: fileName,
      createdAt: DateTime.now(),
      status: DownloadStatus.queued,
    );
    state = [item, ...state];
    await _persist();

    _replace(id, item.copyWith(status: DownloadStatus.downloading));

    try {
      final response = await _dio.get<List<int>>(
        url.toString(),
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          final current = state.where((entry) => entry.id == id).firstOrNull;
          if (current != null) {
            _replace(id, current.copyWith(progress: progress.clamp(0, 1)));
          }
        },
      );

      final bytes = Uint8List.fromList(response.data ?? const <int>[]);
      if (bytes.isEmpty) throw StateError('فایل خالی دریافت شد.');

      final parts = _splitFileName(fileName);
      final savedLocation = await FileSaver.instance.saveFile(
        name: parts.$1,
        bytes: bytes,
        fileExtension: parts.$2,
        mimeType: MimeType.other,
      );

      final current = state.where((entry) => entry.id == id).firstOrNull;
      if (current != null) {
        _replace(
          id,
          current.copyWith(
            status: DownloadStatus.completed,
            progress: 1,
            savedLocation: savedLocation,
          ),
        );
      }
    } on Object catch (error) {
      final current = state.where((entry) => entry.id == id).firstOrNull;
      if (current != null) {
        _replace(
          id,
          current.copyWith(
            status: DownloadStatus.failed,
            errorMessage: error.toString(),
          ),
        );
      }
    }

    await _persist();
  }

  Future<void> retry(String id) async {
    final item = state.where((entry) => entry.id == id).firstOrNull;
    if (item == null) return;
    await remove(id);
    await start(item.url, suggestedFileName: item.fileName);
  }

  Future<void> remove(String id) async {
    state = state.where((entry) => entry.id != id).toList(growable: false);
    await _persist();
  }

  void _replace(String id, DownloadItem replacement) {
    state = [
      for (final item in state)
        if (item.id == id) replacement else item,
    ];
  }

  String _resolveFileName(Uri url, String? suggested) {
    final preferred = suggested?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    }
    final segment = url.pathSegments.where((part) => part.isNotEmpty).lastOrNull;
    if (segment != null && segment.contains('.')) {
      return Uri.decodeComponent(segment)
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    }
    return 'rad-download-$idFallback.bin';
  }

  String get idFallback => DateTime.now().millisecondsSinceEpoch.toString();

  (String, String) _splitFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return (fileName, 'bin');
    return (fileName.substring(0, dot), fileName.substring(dot + 1));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      state.map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }

  E? get lastOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    var value = iterator.current;
    while (iterator.moveNext()) {
      value = iterator.current;
    }
    return value;
  }
}
