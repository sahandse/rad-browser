import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RadBackupService {
  static const _format = 'rad-backup';
  static const _version = 1;
  static const _excludedKeys = <String>{'rad.downloads.v1'};

  Future<int> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, Object?>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('rad.') || _excludedKeys.contains(key)) continue;
      final value = prefs.get(key);
      final encoded = _encodePreference(value);
      if (encoded != null) data[key] = encoded;
    }

    final payload = <String, Object?>{
      'format': _format,
      'version': _version,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final stamp = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    await FileSaver.instance.saveFile(
      name: 'rad-backup-$stamp',
      bytes: bytes,
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
    return data.length;
  }

  Future<RadBackupImportResult?> importBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final bytes = picked.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('فایل انتخاب‌شده قابل خواندن نیست.');
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('ساختار فایل پشتیبان معتبر نیست.');
    }
    if (decoded['format'] != _format || decoded['version'] != _version) {
      throw const FormatException('نسخه فایل پشتیبان با راد سازگار نیست.');
    }
    final rawData = decoded['data'];
    if (rawData is! Map<String, Object?>) {
      throw const FormatException('داده‌های فایل پشتیبان معتبر نیست.');
    }

    final prefs = await SharedPreferences.getInstance();
    var restored = 0;
    for (final entry in rawData.entries) {
      final key = entry.key;
      if (!key.startsWith('rad.') || _excludedKeys.contains(key)) continue;
      if (await _restorePreference(prefs, key, entry.value)) restored++;
    }

    return RadBackupImportResult(
      restoredKeys: restored,
      createdAt: DateTime.tryParse(decoded['createdAt'] as String? ?? ''),
    );
  }

  Map<String, Object?>? _encodePreference(Object? value) {
    if (value is String) return {'type': 'string', 'value': value};
    if (value is bool) return {'type': 'bool', 'value': value};
    if (value is int) return {'type': 'int', 'value': value};
    if (value is double) return {'type': 'double', 'value': value};
    if (value is List<String>) {
      return {'type': 'stringList', 'value': value};
    }
    return null;
  }

  Future<bool> _restorePreference(
    SharedPreferences prefs,
    String key,
    Object? encoded,
  ) async {
    if (encoded is! Map<String, Object?>) return false;
    final type = encoded['type'];
    final value = encoded['value'];
    switch (type) {
      case 'string':
        return value is String ? prefs.setString(key, value) : false;
      case 'bool':
        return value is bool ? prefs.setBool(key, value) : false;
      case 'int':
        return value is int ? prefs.setInt(key, value) : false;
      case 'double':
        return value is num ? prefs.setDouble(key, value.toDouble()) : false;
      case 'stringList':
        if (value is! List) return false;
        final list = value.whereType<String>().toList(growable: false);
        return prefs.setStringList(key, list);
      default:
        return false;
    }
  }
}

class RadBackupImportResult {
  const RadBackupImportResult({
    required this.restoredKeys,
    this.createdAt,
  });

  final int restoredKeys;
  final DateTime? createdAt;
}
