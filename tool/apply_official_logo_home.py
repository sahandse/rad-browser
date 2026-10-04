from pathlib import Path

path = Path('lib/features/home/presentation/pages/home_page.dart')
text = path.read_text(encoding='utf-8')

import_line = "import '../../../../core/widgets/rad_brand_logo.dart';\n"
anchor = "import '../../../../core/utils/url_utils.dart';\n"
if import_line not in text:
    text = text.replace(anchor, anchor + import_line, 1)

text = text.replace('const _RadLogo(),', 'const RadBrandLogo(),', 1)

start = text.find('class _RadLogo extends StatelessWidget {')
end = text.find('class _GoogleLikeSearchBox extends StatefulWidget {')
if start != -1 and end != -1 and end > start:
    text = text[:start] + text[end:]
elif 'class _RadLogo extends StatelessWidget {' in text:
    raise SystemExit('Could not remove legacy _RadLogo block safely')

if 'const RadBrandLogo(),' not in text:
    raise SystemExit('Official RAD logo was not wired into Home')
if 'class _RadLogo extends StatelessWidget {' in text:
    raise SystemExit('Legacy Home logo still exists')

path.write_text(text, encoding='utf-8')
print('Official RAD logo wired into Home')
