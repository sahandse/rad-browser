class UrlUtils {
  const UrlUtils._();

  static bool looksLikeUrl(String input) {
    final value = input.trim();
    if (value.isEmpty || value.contains(' ')) return false;
    final normalized = value.toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.contains('.');
  }

  static Uri resolve(String input) {
    final value = input.trim();
    if (looksLikeUrl(value)) {
      final withScheme = value.startsWith('http://') || value.startsWith('https://')
          ? value
          : 'https://$value';
      return Uri.parse(withScheme);
    }

    return Uri.https('www.google.com', '/search', {'q': value});
  }

  static bool isIrDomain(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'ir' || host.endsWith('.ir');
  }
}
