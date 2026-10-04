import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'rad_search_service.dart';

class RadKnowledgeCard {
  const RadKnowledgeCard({
    required this.title,
    required this.summary,
    required this.sourceUrl,
    required this.host,
    this.imageUrl,
  });

  final String title;
  final String summary;
  final String sourceUrl;
  final String host;
  final String? imageUrl;
}

class RadNewsItem {
  const RadNewsItem({
    required this.title,
    required this.url,
    required this.source,
    required this.snippet,
    this.imageUrl,
  });

  final String title;
  final String url;
  final String source;
  final String snippet;
  final String? imageUrl;
}

class RadAnswerBox {
  const RadAnswerBox({required this.label, required this.value, required this.detail});

  final String label;
  final String value;
  final String detail;
}

class RadSmartSearchService {
  RadSmartSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.7',
  };

  Future<RadKnowledgeCard?> knowledgeCard(RadSearchItem? first) async {
    if (first == null) return null;
    final uri = Uri.tryParse(first.url);
    if (uri == null || !uri.hasScheme) return null;
    try {
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 7));
      if (response.statusCode < 200 || response.statusCode >= 400) return null;
      final doc = html_parser.parse(response.body);
      final title = _clean(
        doc.querySelector('meta[property="og:title"]')?.attributes['content'] ??
            doc.querySelector('title')?.text ??
            first.title,
      );
      final description = _clean(
        doc.querySelector('meta[property="og:description"]')?.attributes['content'] ??
            doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            first.snippet,
      );
      var image = doc.querySelector('meta[property="og:image"]')?.attributes['content']?.trim();
      if (image != null && image.isNotEmpty) {
        image = uri.resolve(image).toString();
      }
      if (title.isEmpty || description.length < 20) return null;
      return RadKnowledgeCard(
        title: title,
        summary: description.length > 360 ? '${description.substring(0, 360)}…' : description,
        sourceUrl: first.url,
        host: first.host,
        imageUrl: image,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<RadNewsItem>> searchNews(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];
    try {
      final uri = Uri.https('www.bing.com', '/news/search', {
        'q': clean,
        'setlang': 'fa',
      });
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 400) return const [];
      final doc = html_parser.parse(response.body);
      final out = <RadNewsItem>[];
      final seen = <String>{};
      for (final node in doc.querySelectorAll('.news-card, .newsitem, .cardcommon, .t_s')) {
        final anchor = node.querySelector('a.title, a[href]');
        if (anchor == null) continue;
        final url = anchor.attributes['href']?.trim() ?? '';
        final parsed = Uri.tryParse(url);
        if (parsed == null || !parsed.hasScheme || seen.contains(url)) continue;
        final title = _clean(anchor.text.isEmpty ? anchor.attributes['aria-label'] ?? '' : anchor.text);
        if (title.length < 4) continue;
        final source = _clean(
          node.querySelector('.source, .provider, .caption, .tptt')?.text ?? parsed.host.replaceFirst('www.', ''),
        );
        final snippet = _clean(node.querySelector('.snippet, .description, p')?.text ?? '');
        final img = node.querySelector('img');
        final image = img?.attributes['data-src'] ?? img?.attributes['src'];
        seen.add(url);
        out.add(RadNewsItem(
          title: title,
          url: url,
          source: source,
          snippet: snippet,
          imageUrl: image,
        ));
        if (out.length >= 24) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> suggestions(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return const [];
    try {
      final uri = Uri.https('suggestqueries.google.com', '/complete/search', {
        'client': 'firefox',
        'hl': 'fa',
        'q': clean,
      });
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 400) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.length < 2 || decoded[1] is! List) return const [];
      return (decoded[1] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(8)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> recentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('rad.searchHistory.v1') ?? const [];
  }

  Future<void> rememberSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('rad.searchHistory.v1') ?? <String>[];
    final next = <String>[clean, ...existing.where((e) => e != clean)].take(20).toList();
    await prefs.setStringList('rad.searchHistory.v1', next);
  }

  List<RadSearchItem> rankResults(String query, List<RadSearchItem> input) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.length > 1)
        .toList(growable: false);
    final indexed = input.indexed.toList(growable: false);
    indexed.sort((a, b) {
      int score(RadSearchItem item, int index) {
        var value = 1000 - index;
        final title = item.title.toLowerCase();
        final snippet = item.snippet.toLowerCase();
        final host = item.host.toLowerCase();
        final uri = Uri.tryParse(item.url);
        if (uri?.scheme == 'https') value += 30;
        if (host.endsWith('.ir')) value += 18;
        for (final term in terms) {
          if (title == term) value += 120;
          if (title.startsWith(term)) value += 55;
          if (title.contains(term)) value += 35;
          if (host.contains(term)) value += 25;
          if (snippet.contains(term)) value += 10;
        }
        return value;
      }

      final sa = score(a.$2, a.$1);
      final sb = score(b.$2, b.$1);
      return sb.compareTo(sa);
    });
    return indexed.map((e) => e.$2).toList(growable: false);
  }

  RadAnswerBox? answerBox(String query) {
    final clean = query.trim().replaceAll('×', '*').replaceAll('÷', '/');
    final math = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(-?\d+(?:\.\d+)?)\s*$').firstMatch(clean);
    if (math != null) {
      final a = double.tryParse(math.group(1)!);
      final b = double.tryParse(math.group(3)!);
      final op = math.group(2)!;
      if (a != null && b != null && !(op == '/' && b == 0)) {
        final result = switch (op) {
          '+' => a + b,
          '-' => a - b,
          '*' => a * b,
          '/' => a / b,
          _ => 0,
        };
        final value = result == result.roundToDouble() ? result.toInt().toString() : result.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
        return RadAnswerBox(label: 'ماشین حساب', value: value, detail: clean);
      }
    }

    final q = clean.toLowerCase();
    final now = DateTime.now();
    if (q == 'ساعت' || q.contains('ساعت الان') || q.contains('زمان الان')) {
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      return RadAnswerBox(label: 'زمان دستگاه', value: '$hh:$mm', detail: 'بر اساس ساعت دستگاه شما');
    }
    if (q == 'تاریخ' || q.contains('تاریخ امروز')) {
      final y = now.year.toString();
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      return RadAnswerBox(label: 'تاریخ امروز', value: '$y/$m/$d', detail: 'تاریخ میلادی دستگاه');
    }
    return null;
  }

  String _clean(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
