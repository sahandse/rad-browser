from pathlib import Path

path = Path('lib/features/home/presentation/pages/home_page.dart')
text = path.read_text(encoding='utf-8')

needle = "import '../../../search/presentation/pages/search_results_page.dart';\n"
replacement = "import '../../../search/presentation/pages/search_results_page.dart';\nimport '../../../search/presentation/widgets/rad_suggesting_search_box.dart';\n"
if 'rad_suggesting_search_box.dart' not in text:
    if needle not in text:
        raise SystemExit('search import anchor not found')
    text = text.replace(needle, replacement, 1)

if '_RadHomeSearchBox(' not in text:
    raise SystemExit('home search widget anchor not found')
text = text.replace('_RadHomeSearchBox(', 'RadSuggestingSearchBox(', 1)

path.write_text(text, encoding='utf-8')
print('Home smart suggestions wired')
