import json
import re
from pathlib import Path

# --- Home: automatic engine selection, remove visible engine picker ---
home = Path('lib/features/home/presentation/pages/home_page.dart')
text = home.read_text(encoding='utf-8')

policy_import = "import '../../../search/domain/automatic_search_engine.dart';\n"
anchor = "import '../../../search/presentation/pages/search_results_page.dart';\n"
if policy_import not in text:
    if anchor not in text:
        raise SystemExit('home search import anchor not found')
    text = text.replace(anchor, policy_import + anchor, 1)

text = text.replace(
    "import '../../../settings/presentation/controllers/settings_controller.dart';\n",
    '',
)

old_mode = """    final mode = ref.read(networkModeProvider).valueOrNull;\n"""
new_mode = """    final mode = ref.read(networkModeProvider).valueOrNull ??\n        await ref.read(networkProbeServiceProvider).check();\n"""
if old_mode not in text:
    raise SystemExit('home mode anchor not found')
text = text.replace(old_mode, new_mode, 1)

old_search = """    if (mode == NetworkMode.internalOnly || mode == NetworkMode.offline) {\n      _openIranDirectory(context, initialQuery: value);\n      return;\n    }\n\n    final engine = ref.read(settingsProvider).searchEngine;\n    Navigator.of(context).push(\n      MaterialPageRoute<void>(\n        builder: (_) => RadSearchResultsPage(query: value, engine: engine),\n      ),\n    );\n"""
new_search = """    final engine = automaticSearchEngine(mode);\n    if (engine == null) {\n      _openIranDirectory(context, initialQuery: value);\n      return;\n    }\n\n    Navigator.of(context).push(\n      MaterialPageRoute<void>(\n        builder: (_) => RadSearchResultsPage(query: value, engine: engine),\n      ),\n    );\n"""
if old_search not in text:
    raise SystemExit('home search routing anchor not found')
text = text.replace(old_search, new_search, 1)

text = text.replace("    final settings = ref.watch(settingsProvider);\n", '')

selector_block = re.compile(
    r"\n\s*const SizedBox\(height: 14\),\n\s*if \(mode == NetworkMode\.fullInternet \|\| mode == null\)\n\s*_SearchEngineSelector\([\s\S]*?\),\n\s*const SizedBox\(height: 10\),",
    re.MULTILINE,
)
text, n = selector_block.subn("\n                      const SizedBox(height: 10),", text, count=1)
if n != 1:
    raise SystemExit('home selector block not found')

start = text.find('class _SearchEngineSelector extends StatelessWidget')
end = text.find('class _RoundActionButton extends StatelessWidget')
if start == -1 or end == -1 or end <= start:
    raise SystemExit('home selector class bounds not found')
text = text[:start] + text[end:]

home.write_text(text, encoding='utf-8')

# --- Browser address bar: use same automatic policy ---
browser = Path('lib/features/browser/presentation/pages/browser_page.dart')
text = browser.read_text(encoding='utf-8')

iran_import = "import '../../../iran_directory/presentation/pages/iran_directory_page.dart';\n"
anchor = "import '../../../history/presentation/pages/history_page.dart';\n"
if iran_import not in text:
    if anchor not in text:
        raise SystemExit('browser history import anchor not found')
    text = text.replace(anchor, anchor + iran_import, 1)

policy_import = "import '../../../search/domain/automatic_search_engine.dart';\n"
anchor = "import '../../../search/presentation/pages/search_results_page.dart';\n"
if policy_import not in text:
    if anchor not in text:
        raise SystemExit('browser search import anchor not found')
    text = text.replace(anchor, policy_import + anchor, 1)

old_resolve = """    return settings.searchEngine.searchUri(value);\n"""
new_resolve = """    final mode = ref.read(networkModeProvider).valueOrNull;\n    final engine = mode == NetworkMode.internalOnly\n        ? RadSearchEngine.zarebin\n        : RadSearchEngine.google;\n    return engine.searchUri(value);\n"""
if old_resolve not in text:
    raise SystemExit('browser resolve anchor not found')
text = text.replace(old_resolve, new_resolve, 1)

old_nav = """    if (!UrlUtils.looksLikeUrl(trimmed)) {\n      FocusManager.instance.primaryFocus?.unfocus();\n      final engine = ref.read(settingsProvider).searchEngine;\n      await Navigator.of(context).push(\n        MaterialPageRoute<void>(\n          builder: (_) => RadSearchResultsPage(query: trimmed, engine: engine),\n        ),\n      );\n      return;\n    }\n"""
new_nav = """    if (!UrlUtils.looksLikeUrl(trimmed)) {\n      FocusManager.instance.primaryFocus?.unfocus();\n      final mode = ref.read(networkModeProvider).valueOrNull ??\n          await ref.read(networkProbeServiceProvider).check();\n      final engine = automaticSearchEngine(mode);\n      if (engine == null) {\n        await Navigator.of(context).push(\n          MaterialPageRoute<void>(\n            builder: (_) => IranDirectoryPage(initialQuery: trimmed),\n          ),\n        );\n        return;\n      }\n      await Navigator.of(context).push(\n        MaterialPageRoute<void>(\n          builder: (_) => RadSearchResultsPage(query: trimmed, engine: engine),\n        ),\n      );\n      return;\n    }\n"""
if old_nav not in text:
    raise SystemExit('browser navigate search anchor not found')
text = text.replace(old_nav, new_nav, 1)

browser.write_text(text, encoding='utf-8')

# --- Search service: Google-only when global, more Google results; Zarebin-only internally ---
service = Path('lib/features/search/data/rad_search_service.dart')
text = service.read_text(encoding='utf-8')

old_google_order = """      RadSearchEngine.google => const [\n          RadSearchEngine.google,\n          RadSearchEngine.duckDuckGo,\n          RadSearchEngine.bing,\n        ],\n"""
new_google_order = """      RadSearchEngine.google => const [\n          RadSearchEngine.google,\n        ],\n"""
if old_google_order not in text:
    raise SystemExit('google order anchor not found')
text = text.replace(old_google_order, new_google_order, 1)

old_z_order = """      RadSearchEngine.zarebin => const [\n          RadSearchEngine.zarebin,\n          RadSearchEngine.google,\n          RadSearchEngine.duckDuckGo,\n        ],\n"""
new_z_order = """      RadSearchEngine.zarebin => const [\n          RadSearchEngine.zarebin,\n        ],\n"""
if old_z_order not in text:
    raise SystemExit('zarebin order anchor not found')
text = text.replace(old_z_order, new_z_order, 1)

text = text.replace("      'num': '30',", "      'num': '50',", 1)
text = text.replace('      if (results.length >= 30) break;', '      if (results.length >= 50) break;', 1)

service.write_text(text, encoding='utf-8')

# --- Iran Web: remove Zarebin from directory data only ---
sites_path = Path('assets/data/iran_sites.json')
doc = json.loads(sites_path.read_text(encoding='utf-8'))
sites = doc.get('sites', [])
filtered = []
removed = 0
for site in sites:
    haystack = ' '.join([
        str(site.get('id', '')),
        str(site.get('name', '')),
        str(site.get('url', '')),
    ]).lower()
    if 'zarebin' in haystack or 'ذره' in haystack:
        removed += 1
        continue
    filtered.append(site)
doc['sites'] = filtered
if 'version' in doc and isinstance(doc['version'], int):
    doc['version'] += 1
sites_path.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Removed {removed} Zarebin Iran Web entries')

# --- Settings: automatic search explanation instead of manual picker ---
settings = Path('lib/features/settings/presentation/pages/settings_page.dart')
text = settings.read_text(encoding='utf-8')

old_tile = """              ListTile(\n                leading: const Icon(Icons.search_rounded),\n                title: const Text('موتور جستجو'),\n                subtitle: Text(settings.searchEngine.title),\n                onTap: () => _showSearchEnginePicker(\n                  context,\n                  ref,\n                  settings.searchEngine,\n                ),\n              ),\n"""
new_tile = """              const ListTile(\n                leading: Icon(Icons.auto_awesome_rounded),\n                title: Text('موتور جستجو'),\n                subtitle: Text('خودکار: Google با اینترنت جهانی، ذره‌بین در شبکه داخلی'),\n              ),\n"""
if old_tile not in text:
    raise SystemExit('settings search tile anchor not found')
text = text.replace(old_tile, new_tile, 1)

start = text.find('  Future<void> _showSearchEnginePicker(')
end = text.find('  Future<void> _showTrackingPicker(')
if start != -1 and end != -1 and end > start:
    text = text[:start] + text[end:]

settings.write_text(text, encoding='utf-8')

# --- Version + changelog ---
pubspec = Path('pubspec.yaml')
text = pubspec.read_text(encoding='utf-8')
text = text.replace('version: 1.1.0+3', 'version: 1.1.1+4', 1)
pubspec.write_text(text, encoding='utf-8')

changelog = Path('CHANGELOG.md')
text = changelog.read_text(encoding='utf-8')
entry = """## 1.1.1 — Automatic Search Routing\n\n- حذف انتخاب دستی Google / ذره‌بین از صفحه اصلی\n- انتخاب خودکار Google هنگام دسترسی به اینترنت جهانی\n- انتخاب خودکار ذره‌بین هنگام دسترسی فقط به شبکه داخلی\n- استفاده از ایران‌وب/داده محلی در حالت کاملاً آفلاین\n- حذف ذره‌بین از فهرست سایت‌های ایران‌وب\n- افزایش نتایج Google تا ۵۰ نتیجه با بارگذاری تدریجی در UI\n- یکسان‌سازی رفتار جستجو در Home و Address Bar\n\n"""
if '## 1.1.1 — Automatic Search Routing' not in text:
    text = text.replace('# Changelog\n\n', '# Changelog\n\n' + entry, 1)
changelog.write_text(text, encoding='utf-8')

print('Automatic search routing patch complete')
