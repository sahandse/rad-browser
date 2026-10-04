from pathlib import Path
p = Path('lib/features/search/presentation/pages/search_results_page.dart')
s = p.read_text(encoding='utf-8')
bad = """              Expanded(\n                        child: Text(\n                          'نتایج با ${usedEngine.title} تکمیل شدند',\n                          textDirection: TextDirection.rtl,\n                          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n              Expanded(\n"""
good = """              Expanded(\n"""
if bad not in s:
    raise SystemExit('broken provider block not found')
s = s.replace(bad, good, 1)
s = s.replace("  RadSearchEngine? _usedEngine;\n", "")
s = s.replace("      _usedEngine = null;\n", "")
s = s.replace("        _usedEngine = response.usedEngine;\n", "")
p.write_text(s, encoding='utf-8')
print('search results syntax repaired')
