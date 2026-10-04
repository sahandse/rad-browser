import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/iran_site.dart';

class IranDirectoryRepository {
  Future<List<IranSite>> loadBundled() async {
    final raw = await rootBundle.loadString('assets/data/iran_sites.json');
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final sites = (decoded['sites'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(IranSite.fromJson)
        .where((site) => site.verified)
        .toList(growable: false);
    sites.sort((a, b) => b.priority.compareTo(a.priority));
    return sites;
  }
}
