from pathlib import Path

path = Path('lib/features/browser/presentation/pages/browser_page.dart')
text = path.read_text(encoding='utf-8')

import_anchor = "import '../../../reader/presentation/pages/reader_page.dart';\n"
search_import = "import '../../../search/presentation/pages/search_results_page.dart';\n"
if search_import not in text:
    text = text.replace(import_anchor, import_anchor + search_import, 1)

old = '''  Future<void> _navigate(String value) async {\n    if (value.trim().isEmpty) return;\n    final uri = _resolveInput(value);\n    FocusManager.instance.primaryFocus?.unfocus();\n'''
new = '''  Future<void> _navigate(String value) async {\n    final trimmed = value.trim();\n    if (trimmed.isEmpty) return;\n    if (!UrlUtils.looksLikeUrl(trimmed)) {\n      FocusManager.instance.primaryFocus?.unfocus();\n      final engine = ref.read(settingsProvider).searchEngine;\n      await Navigator.of(context).push(\n        MaterialPageRoute<void>(\n          builder: (_) => RadSearchResultsPage(query: trimmed, engine: engine),\n        ),\n      );\n      return;\n    }\n    final uri = _resolveInput(trimmed);\n    FocusManager.instance.primaryFocus?.unfocus();\n'''
if old not in text:
    raise SystemExit('Expected _navigate block not found')
text = text.replace(old, new, 1)

if search_import not in text or 'RadSearchResultsPage(query: trimmed, engine: engine)' not in text:
    raise SystemExit('Native search navigation patch validation failed')

path.write_text(text, encoding='utf-8')
print('Browser address bar now opens native RAD search results')
