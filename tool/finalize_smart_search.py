from pathlib import Path

# Home: wire the new suggesting search widget and remove the old private implementation.
home = Path('lib/features/home/presentation/pages/home_page.dart')
text = home.read_text(encoding='utf-8')
import_anchor = "import '../../../search/presentation/pages/search_results_page.dart';\n"
smart_import = "import '../../../search/presentation/widgets/rad_suggesting_search_box.dart';\n"
if smart_import not in text:
    if import_anchor not in text:
        raise SystemExit('home import anchor not found')
    text = text.replace(import_anchor, import_anchor + smart_import, 1)
text = text.replace('_RadHomeSearchBox(', 'RadSuggestingSearchBox(', 1)
start = text.find('class _RadHomeSearchBox extends StatefulWidget')
end = text.find('class _SearchEngineSelector extends StatelessWidget')
if start != -1 and end != -1 and end > start:
    text = text[:start] + text[end:]
home.write_text(text, encoding='utf-8')

# Smart search service: honor the user's local search-history preference.
service = Path('lib/features/search/data/rad_smart_search_service.dart')
text = service.read_text(encoding='utf-8')
old_recent = """  Future<List<String>> recentSearches() async {\n    final prefs = await SharedPreferences.getInstance();\n    return prefs.getStringList('rad.searchHistory.v1') ?? const [];\n  }\n"""
new_recent = """  Future<List<String>> recentSearches() async {\n    final prefs = await SharedPreferences.getInstance();\n    if (prefs.getBool('rad.searchHistory.enabled') == false) return const [];\n    return prefs.getStringList('rad.searchHistory.v1') ?? const [];\n  }\n"""
if old_recent in text:
    text = text.replace(old_recent, new_recent, 1)
old_remember = """  Future<void> rememberSearch(String query) async {\n    final clean = query.trim();\n    if (clean.isEmpty) return;\n    final prefs = await SharedPreferences.getInstance();\n    final existing = prefs.getStringList('rad.searchHistory.v1') ?? <String>[];\n"""
new_remember = """  Future<void> rememberSearch(String query) async {\n    final clean = query.trim();\n    if (clean.isEmpty) return;\n    final prefs = await SharedPreferences.getInstance();\n    if (prefs.getBool('rad.searchHistory.enabled') == false) return;\n    final existing = prefs.getStringList('rad.searchHistory.v1') ?? <String>[];\n"""
if old_remember in text:
    text = text.replace(old_remember, new_remember, 1)
service.write_text(text, encoding='utf-8')

# Settings: expose search history privacy controls.
settings = Path('lib/features/settings/presentation/pages/settings_page.dart')
text = settings.read_text(encoding='utf-8')
settings_import = "import '../../../search/presentation/widgets/search_history_settings_tile.dart';\n"
anchor = "import '../../../privacy/presentation/pages/tracking_exceptions_page.dart';\n"
if settings_import not in text:
    if anchor not in text:
        raise SystemExit('settings import anchor not found')
    text = text.replace(anchor, anchor + settings_import, 1)
search_block = """              ListTile(\n                leading: const Icon(Icons.search_rounded),\n                title: const Text('موتور جستجو'),\n                subtitle: Text(settings.searchEngine.title),\n                onTap: () => _showSearchEnginePicker(\n                  context,\n                  ref,\n                  settings.searchEngine,\n                ),\n              ),\n"""
replacement = search_block + """              const Divider(height: 1),\n              const SearchHistorySettingsTile(),\n"""
if 'const SearchHistorySettingsTile()' not in text:
    if search_block not in text:
        raise SystemExit('settings search block not found')
    text = text.replace(search_block, replacement, 1)
settings.write_text(text, encoding='utf-8')

# Version bump for the smart-search release candidate.
pubspec = Path('pubspec.yaml')
text = pubspec.read_text(encoding='utf-8')
text = text.replace('version: 1.0.1+2', 'version: 1.1.0+3', 1)
pubspec.write_text(text, encoding='utf-8')

print('Smart search finalization applied')
